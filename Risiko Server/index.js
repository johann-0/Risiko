import { WebSocketServer } from 'ws';

class PlayerBaseInfo {
  id = 0;
  name = "default name";
  color = 0;
  constructor(id, name, color) { this.id = id; this.name = name; this.color = color; }
  toString() { return JSON.stringify(this.toJSON()); }
  toJSON() { return {"id": this.id,"name": this.name, "color": this.color}; }
}

class Province {
  id = -1;
  owner = -1;
  soldiers = 0;
  to_add = 0;
  constructor(pID, pOwner, pSoldiers, pToAdd) { this.id = pID; this.owner = pOwner; this.soldiers = pSoldiers; this.to_add = pToAdd; }
  toString() { return JSON.stringify(this.toJSON()); }
  toJSON() { return {"id": this.id, "owner": this.owner, "soldiers": this.soldiers, "to_add": this.to_add}; }
}

let game_state = {
  "cur_phase": "lobby", // lobby -> init_deploy -> [deploy, attack, move]
  "cur_turn" : 0,
  "prov_selected": -1,
  "provinces": [],
  "avail_troops": 0,
  "random_deployment": false,
}

let players = [];
const NUM_OF_PROV = 42;

const wss = new WebSocketServer({ port: 8080 });

let resetServer = function () {
  wss.clients.forEach((ws)=>{
    ws.close()
  })
  game_state = {
    "cur_phase": "lobby", // lobby -> init_deploy -> [deploy, attack, move]
    "cur_turn" : 0,
    "prov_selected": -1,
    "provinces": [],
    "avail_troops": 0,
    "random_deployment": false,
  }
  players = []
}
// Function from https://stackoverflow.com/questions/2450954/how-to-randomize-shuffle-a-javascript-array
function shuffle_arr(array) {
  let currentIndex = array.length;
  while (currentIndex != 0) { // While there remain elements to shuffle
    let randomIndex = Math.floor(Math.random() * currentIndex); // Pick a remaining element...
    --currentIndex;
    [array[currentIndex], array[randomIndex]] = [ // And swap it with the current element.
      array[randomIndex], array[currentIndex]];
  }
}
let distributeProvinces = function (provs_per_player) {
  // Array shows each provinces owners (initially no owner = -1)
  let prov_owners = [];
  provs_per_player.forEach((n_provs, owner_idx)=>{
    prov_owners = prov_owners.concat(Array.from({length: n_provs}, ()=>owner_idx))
  });
  shuffle_arr(prov_owners);
  game_state["provinces"].forEach((province, index)=>{
    province.owner = prov_owners[index];
  });
  return prov_owners;
}

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
let calculateSoldiers = function (player_index) {
  let toReturn = 0;
  let owned_provs = 0;
  //                [na, sa, af, eu, as, oc]
  let last_provs  = [ 8, 12, 18, 25, 37, 41];
  let bonuses     = [ 5,  2,  3,  5,  7,  2];
  let cont_full = true;
  let cont_idx = 0;
  game_state["provinces"].forEach((prov)=>{
    if (prov.owner == player_index)
      owned_provs += 1;
    else
      cont_full = false;
    if (prov.id == last_provs[cont_idx]) {
      if(cont_full == true)
        toReturn += bonuses[cont_idx];
      cont_idx += 1;
      cont_full = true;
    }
  });
  toReturn += Math.floor(owned_provs / 3);
  if (toReturn < 3)
    return 3;
  else
    return toReturn;
}

let sendPlayersData = function() {
  let index = 0;
  wss.clients.forEach((ws)=>{
    let toSend_json = {"message_type":"lobby_data", "data":[], "index":index, "random_deployment":game_state["random_deployment"]};
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
let sendProvUpdated = function(provID, avail_soldiers) {
  let prov = game_state["provinces"][provID];
  let index = 0;
  wss.clients.forEach((ws)=>{
    let toSend_json = {"message_type": "prov_updated", "data": {"prov": prov.toJSON(), "avail_soldiers": avail_soldiers}};
    console.log("SENDING: " + JSON.stringify(toSend_json));
    ws.send(JSON.stringify(toSend_json));
    index += 1;
  });
}
let sendEndTurn = function(newPlayerID) {
  let index = 0;
  wss.clients.forEach((ws)=>{
    let avail_soldiers = 0
    switch (game_state["cur_phase"]) {
      case "init_deploy":
        avail_soldiers = 1
        break;
      case "deploy":
        // Calculate how many soldiers a player has
        avail_soldiers = calculateSoldiers(index);
      default: break;
    }
    let toSend_json = {"message_type": "end_turn", "data": {"new_player_id": newPlayerID, "avail_soldiers": avail_soldiers, "phase": game_state["cur_phase"]}};
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
        game_state["cur_turn"] = 0;
        for (let i = 0; i < NUM_OF_PROV; ++i) {
          game_state["provinces"].push(new Province(i, -1, 0, 0));
        }
        game_state["cur_phase"] = "init_deploy";

        // Get available colors
        let avail_colors = [0x0000FFFF, 0xFF0000FF, 0x00FF00FF, 0xFFFF00FF]; // brgy
        players.forEach((player)=>{
          for (let i = 0; i < avail_colors.length; ++i) {
            if (avail_colors[i] == player.color) {
              avail_colors.splice(i, 1);
              break;
            };
          };
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
        // Send start_game message to everyone, tell them who starts
        let toSend_json = {};
        if (game_state["random_deployment"] == false) {
          toSend_json = {
            "message_type": "start_game",
            "turn": game_state["cur_turn"], // The index of the player whose turn it is
          };
        } else {
          // Distribute the provinces
          // Calculate the provinces per player
          let provs = [];
          let remainingProvs = NUM_OF_PROV % players.length;
          for (let i = 0; i < players.length; i++) {
            let toAdd = parseInt(NUM_OF_PROV/players.length);
            if(remainingProvs > 0)
              toAdd += 1;
            provs.push(toAdd);      
          }
          toSend_json = {
            "message_type": "start_game_rand",
            "turn": game_state["cur_turn"],
            "prov_owners": distributeProvinces(provs) // TODO (current working area)
          }
        }
        wss.clients.forEach((_ws)=>{_ws.send(JSON.stringify(toSend_json));});
        console.log("SENDING: " + JSON.stringify(toSend_json));
        break;
      
      // When a player selects a new color or toggles random deployment
      case "lobby_updated":
        // Update the color selection of the player and then send the new lobby data to everyone
        players.forEach((player)=>{
          if (player.id == ws.id) {
            player.color = message_json["data"]["color"];
          }
        });
        game_state["random_deployment"] = message_json["data"]["random_deployment"]
        sendPlayersData();
        break;

      // When the player whose turn it is selects a new province
      case "prov_selected":
        game_state.prov_selected = data["newProvID"];
        sendProvSelected(data["oldProvID"]);
        break;
      
      case "prov_updated":
        let prov_ = data["prov"];
        let prov_info = game_state["provinces"][prov_["id"]];
        prov_info.owner = prov_["owner"];
        prov_info.soldiers = prov_["soldiers"];
        prov_info.to_add = prov_["to_add"];
        let avail_soldiers = data["avail_soldiers"];
        toLog += "province: " + prov_info.toString();
        sendProvUpdated(prov_info.id, avail_soldiers);
        break;
      
      // When new turn
      case "end_turn":
        let oldPlayerID = game_state["cur_turn"];
        let newPlayerID = (oldPlayerID + 1) % players.length;
        game_state["cur_turn"] = newPlayerID;
        toLog += "player_turn: " + oldPlayerID + " -> " + newPlayerID + ". ";
        switch (game_state["cur_phase"]) {
          case "deploy":
            sendEndTurn(newPlayerID)
            break;
          case "init_deploy":
            // Check if all provinces have been taken
            let allTaken = true;
            game_state["provinces"].forEach((province)=>{ if(province.owner == -1) allTaken = false; });
            if (allTaken == false) {
              sendEndTurn(newPlayerID);
            } else {
              toLog += "all provinces are owned. ";
              // Move the game to the next phase (deploying)
              game_state["cur_phase"] = "deploy";
              sendEndTurn(newPlayerID);
            };
            break;
          default:
            print("Unknown game_phase (on end_turn)")
            break;
        }
        break;
      
      // DEFAULT
      default:
        toLog += "unknown(" + msg_type + ")";
    }
    
    print(toLog + "\n");
  });
  
  ws.on("close", (event) => {
    switch (game_state["cur_phase"]) {
      case "lobby":
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
        break;
      default:
        // Disconnect everyone and reset the lobby?
        print("Connection closed (" + ws.id + "). Resetting server.");
        resetServer();
        break;
    }
  })
});