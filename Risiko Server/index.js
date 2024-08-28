import { WebSocketServer } from 'ws';

class PlayerBaseInfo {
  id = 0;
  name = "default name";
  color = 0;
  constructor(id, name, color) {
    this.id = id;
    this.name = name;
    this.color = color;
  }
  toString() {return JSON.stringify(this.toJSON()); }
  toJSON() { return {"id": this.id,"name": this.name, "color": this.color}; }
}

class ProvinceInfo {
  soldiers = 0;
  owner = 0;
}

let gameState = {
  "current turn" : 0,
  "province stats": []
}

let players = []

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
  print(wss.clients.size)
  print("Connection started\n");
  
  
  // Kick the client out
  if (wss.clients.size > 4) {
    print("Too many clients (" + wss.clients.length + "). Trying to close this socket!")
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
        // Resolve the random colors
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
        toLog += "Available colors: " + avail_colors
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
        wss.clients.forEach((_ws)=>{
          _ws.send(JSON.stringify({
            "message_type": "start_game",
            "turn": 0
          }));
        })
        break;
      case "color_selected":
        // Update the color selection of the player and then send the new lobby data to everyone
        players.forEach((player)=>{
          if (player.id == ws.id) {
            player.color = message_json["data"];
          }
        });
        sendPlayersData();
        break;
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