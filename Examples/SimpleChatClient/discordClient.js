/* @flow */
'use strict';

var BASE_DOMAIN = "discordapp.com";
var BASE = `https://${BASE_DOMAIN}`;
var WEBSOCKET_HUB = `wss://${BASE_DOMAIN}/hub`;

var ENDPOINTS = {
  API : `${BASE}/api`,
  LOGIN : `${BASE}/api/auth/login`,
  CHANNELS : `${BASE}/api/channels`
};



export function discordLogin(email: string, password: string): Promise {
  var request = new XMLHttpRequest();
  request.open("POST", ENDPOINTS.LOGIN, true);
  var formdata = new FormData();
  formdata.append('email', email);
  formdata.append('password', password);
  request.send(formdata);
  return new Promise((resolve, reject) => {
    request.onreadystatechange = () => {
      if (request.readyState === request.DONE) {
        if (request.status === 200) {
          resolve(JSON.parse(request.responseText).token);
        } else if (request.status !== 0) {
          reject(request.responseText);
        } else {
          reject(request.responseText);
        }
      }
    };
  });
}

export function getGateway(token: string): Promise {
  return fetch(`${ENDPOINTS.API}/gateway`, {
    headers: {
      authorization: token
    }
  })
  .then(r => r.json())
  .then(r => r.url);
}

export function connect(token: string, gatewayUrl: string, onMessageRecieved: Function): void {
  var websocket = new WebSocket(gatewayUrl);
  websocket.onopen = function () {
		connnectionMessage.bind(this)(token); //try connecting
	};

	websocket.onclose = function () {
		console.log('disconnected');
	}

  websocket.onmessage = function (e) {

      //console.log('onmessage', e.data);
			var data = {};

			try {
				data = JSON.parse(e.data);
			} catch (err) {
				console.error(err);
				return;
			}

      switch(data.t) {
        case "READY":
        var servers = data.d.guilds.map(guild => {
          return {
            name: guild.name,
            channels: guild.channels
              .filter(c => c.type !== 'voice')
              .sort((a, b) => a.position - b.position)
          }
        });
        onMessageRecieved({
          user: data.d.user,
          servers
        });

        setInterval(() => keepAlive.bind(this)(), 10 * 1000);

        break;

        case "MESSAGE_CREATE":
					//console.log('received message', data.d);
					break;
      }
  }


}

function keepAlive() {
  this.send(JSON.stringify({
		op: 1,
		d: Date.now()
	}));
}

function connnectionMessage(token): void {
	var data = {
		op: 2,
		d: {
			token: token,
			v: 3,
			properties: {
				'$os': 'OS X',
				'$browser': 'ReactNativeDesktop',
				'$device': 'macbook',
				'$referrer': '',
				'$referring_domain': ''
			}
		}
	};
  this.send(JSON.stringify(data));
}

export function getMessages(token: string, channelID: string): Promise {
  return fetch(`${ENDPOINTS.CHANNELS}/${channelID}/messages?limit=200`, {
    headers: {
      authorization: token
    }
  })
  .then(r => r.json())
  //.catch(e => console.log(e));
}

export function sendMessageToChannel(token: string, channelID: string, text: string) {
  var request = new XMLHttpRequest();
  request.open('POST', `${ENDPOINTS.CHANNELS}/${channelID}/messages`, true);
  var formdata = new FormData();
  formdata.append('content', text);
  //request.setRequestHeader('authorization', token).
  request.send(formdata);
  return new Promise((resolve, reject) => {
    request.onreadystatechange = () => {
      if (request.readyState === request.DONE) {
        if (request.status === 200) {
          resolve(JSON.parse(request.responseText));
        } else if (request.status !== 0) {
          reject(request.responseText);
        } else {
          reject(request.responseText);
        }
      }
    };
  });
  //
  // return fetch(`${ENDPOINTS.CHANNELS}/${channelID}/messages`, {
  //   method: 'POST',
  //   headers: {
  //     authorization: token
  //   },
  //   body: {
  //     content: content
  //   },
  // })
  // .then(r => r.json())
}
