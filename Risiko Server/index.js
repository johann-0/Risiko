import { WebSocketServer } from 'ws';

class PlayerBaseInfo {
  id = 0;
  name = "default name";
  color = 0;
  constructor(id, name, color) { this.id = id; this.name = name; this.color = color; }
  toString() { return JSON.stringify(this.toJSON()); }
  toJSON() { return {"id": this.id,"name": this.name, "color": this.color}; }
}

class ProvinceInfo {
  id = -1;
  owner = -1;
  soldiers = 0;
  to_add = 0;
  constructor(pID, pOwner, pSoldiers, pToAdd) { this.id = pID; this.owner = pOwner; this.soldiers = pSoldiers; this.to_add = pToAdd; }
  toString() { return JSON.stringify(this.toJSON()); }
  toJSON() { return {"prov_id": this.id, "owner": this.owner, "soldiers": this.soldiers, "to_add": this.to_add}; }
}

let game_state = {
  "cur_phase": "lobby",
  "cur_turn" : 0,
  "prov_selected": -1,
  "prov_stats": []
}

let players = [];
const NUM_OF_PROV = 42;

const wss = new WebSocketServer({ port: 8080 });

let generatePlayerID = function () {
  function isIDunique(id) {
    let toReturn = true;
    players.forEach((player) => { if (id == player.id) toReturn = false; });
    return toReturn;
  }
  let newID = 0;
  do { newID = Math.abs(parseInt(Math.random() * 1000)) % 100; } while(isIDunique(newID) == false);
  return newID;
}

let sendPlayersData = function() {
  let index = 0;
  wss.clients.forEach((ws)=>{
    let toSend_json = {"message_type":"lobby_data","data":[],"index":index};
    players.forEach((player) => {
      toSend_json["data"].push(player.toJSON());
    });
    console.log("SENDING: " + JSON.stringify(toSend_json));
    ws.send(JSON.stringify(toSend_json));
    index += 1;
  });
}

let sendGameData = function() {
  let index = 0;
  wss.clients.forEach((ws)=>{
    let toSend_json = {"message_type":"game_data","data":game_state};
    console.log("SENDING: " + JSON.stringify(toSend_json));
    ws.send(JSON.stringify(toSend_json));
    index += 1;
  });
}
let sendProvSelected = function(oldProvID) {
  let index = 0;
  wss.clients.forEach((ws)=>{
    let toSend_json = {"message_type":"prov_selected","data":{"newProvID":game_state.prov_selected,"oldProvID": oldProvID}};
    console.log("SENDING: " + JSON.stringify(toSend_json));
    ws.send(JSON.stringify(toSend_json));
    index += 1;
  });
}
let sendProvUpdated = function(provID) {
  let prov = game_state["prov_stats"][provID];
  let index = 0;
  wss.clients.forEach((ws)=>{
    let toSend_json = {"message_type": "prov_updated", "data": prov.toJSON()};
    console.log("SENDING: " + JSON.stringify(toSend_json));
    ws.send(JSON.stringify(toSend_json));
    index += 1;
  });
}

wss.on('connection', function connection(ws) {
  // Basically console.log but with the socket's id
  let print;
  { var log = console.log;
    print = function () {
        var first_parameter = arguments[0];
        var other_parameters = Array.prototype.slice.call(arguments, 1);
        
        log.apply(console, ["[" + ws.id + "] " + first_parameter].concat(other_parameters));
    }; }
  ws.id = generatePlayerID();
  print("Connection started (num. of con.: " + wss.clients.size + ")\n");
  
  // Cases in which the client is kicked out
  if (wss.clients.size > 4) {
    print("Too many clients (" + wss.clients.length + ")! Trying to close this socket.")
    ws.close();
  } else if (game_state["cur_phase"] != "lobby") {
    print("Lobby has closed (" + game_state["cur_phase"] + ")! Trying to close this socket.")
    ws.close();
  }
  
  ws.on('message', (message) => {
    // Print out the message to log
    print("Received: %s", message);
    // Get the message_type
    let message_json = JSON.parse(message);
    let msg_type = message_json["message_type"];
    let data = message_json["data"];
    let toLog = "`-> ";
    
    switch(msg_type) {
      // Just a simple message (for debugging)
      case "message": 
        toLog += "message"
        break;
      
      // Received when a person joins the lobby
      case "player_info": 
        players.push(new PlayerBaseInfo(ws.id, data["name"], data["color"]));
        toLog += "player_info, saved object: " + players[players.length-1];
        // Send lobby_data to everyone (other players' data)
        sendPlayersData();
        break;
      
      // Received when a player wants to start the game
      case "start_game":
        // Initialise game_state
        game_state["cur_turn"] = 0
        for (let i = 0; i < NUM_OF_PROV; ++i) {
          game_state["prov_stats"].push(new ProvinceInfo(i, -1, 0, 0))
        }

        // Get available colors
        let avail_colors = [0x0000FFFF, 0xFF0000FF, 0x00FF00FF, 0xFFFF00FF] // brgy
        players.forEach((player)=>{
          for (let i = 0; i < avail_colors.length; ++i) {
            if (avail_colors[i] == player.color) {
              avail_colors.splice(i,1);
              break;
            }
          }
        });
        //toLog += "Available colors: " + avail_colors
        // Give out the available colors
        players.forEach((player)=>{
          if(player.color == 4043309055) {// 4043309055 is azure
            let i = Math.abs(parseInt(Math.random() * 1000)) % avail_colors.length;
            player.color = avail_colors[i];
            avail_colors.splice(i, 1);
          }
        });
        sendPlayersData();
        // Distribute soldiers among the players
        let soldiers = [];
        let remainingSoldiers = NUM_OF_PROV % players.length;
        for (let i = 0; i < players.length; i++) {
          let toAdd = parseInt(NUM_OF_PROV/players.length);
          if(remainingSoldiers > 0)
            toAdd += 1;
          soldiers.push(toAdd);      
        }
        toLog += ". Soldiers: " + soldiers
        // Send start_game message to everyone, tell them who starts
        wss.clients.forEach((_ws)=>{
          _ws.send(JSON.stringify({
            "message_type": "start_game",
            "turn": game_state["cur_turn"], // The index of the player whose turn it is
            "soldiers": soldiers
          }));
        })
        break;
      
      // When a player selects a new color
      case "color_selected":
        // Update the color selection of the player and then send the new lobby data to everyone
        players.forEach((player)=>{
          if (player.id == ws.id) {
            player.color = message_json["data"];
          }
        });
        sendPlayersData();
        break;

      // When the player whose turn it is selects a new province
      case "prov_selected":
        game_state.prov_selected = data["newProvID"];
        sendProvSelected(data["oldProvID"]);
        break;
      
      case "prov_updated":
        let prov_info = game_state["prov_stats"][data["prov_id"]];
        prov_info.owner = data["owner"];
        prov_info.soldiers = data["soldiers"];
        prov_info.to_add = data["to_add"];
        toLog += "province: " + prov_info.toString()
        sendProvUpdated(prov_info.id);
        break;
      // DEFAULT
      default:
        toLog += "unknown(" + msg_type + ")";
    }
    
    print(toLog + "\n");
  });
  
  ws.on("close", (event) => {
    // Delete this player's data from the lobby
    let indexToDelete = -1;
    let counter = 0;
    players.forEach((player)=>{
      if (player.id == ws.id)
        indexToDelete = counter;
      counter += 1;
    });
    players.splice(indexToDelete, 1)
    
    let players_str = ""
    players.forEach((player)=>{players_str += player.toString() + ", "})
    print("Connection closed (remaining players: %s)", players_str);
    
    // Send new lobby data to all sockets
    sendPlayersData();
    console.log("");
  })
});