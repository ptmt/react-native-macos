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

export function login(email: string, password: string): Promise {
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
          reject();
        } else {
          reject();
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

export function connect(token: string, gatewayUrl: string, setState: Function): void {
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
          }
        });
        setState({
          user: data.d.user,
          servers
        });

        setInterval(() => keepAlive.bind(this)(), 10 * 1000);

        break;

        case "MESSAGE_CREATE":
					console.log('received message', data.d);
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
  return fetch(`${ENDPOINTS.CHANNELS}/${channelID}/messages?limit=100`, {
    headers: {
      authorization: token
    }
  })
  .then(r => r.json())
  .catch(e => console.log(e));
}

// export function getChannels() {
//   self.getGateway().then(function (url) {
// 								self.createws(url);
// 								callback(null, self.token);
// 								resolve(self.token);
// }
