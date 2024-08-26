# ovpn-admin

Simple web UI to manage OpenVPN users, their certificates & routes in Linux. While backend is written in Go, frontend is based on Vue.js.

Originally created in [Flant](https://flant.com/) for internal needs & used for years, then updated to be more modern and [publicly released](https://medium.com/flant-com/introducing-ovpn-admin-a-web-interface-to-manage-openvpn-users-d81705ad8f23) in March'21. Your contributions are welcome!

***DISCLAIMER!** This project was created for experienced users (system administrators) and private (e.g., protected by network policies) environments only. Thus, it is not implemented with security in mind (e.g., it doesn't strictly check all parameters passed by users, etc.). It also relies heavily on files and fails if required files aren't available.*

## Features

* Adding, deleting OpenVPN users (generating certificates for them);
* Revoking/restoring/rotating users certificates;
* Generating ready-to-user config files;
* Providing metrics for Prometheus, including certificates expiration date, number of (connected/total) users, information about connected users;
* (optionally) Specifying CCD (`client-config-dir`) for each user;
* (optionally) Operating in a master/slave mode (syncing certs & CCD with other server);
* (optionally) Specifying/changing password for additional authorization in OpenVPN;
* (optionally) Specifying the Kubernetes LoadBalancer if it's used in front of the OpenVPN server (to get an automatically defined `remote` in the `client.conf.tpl` template).
* (optionally) Storing certificates and other files in Kubernetes Secrets (**Attention, this feature is experimental!**).

### Screenshots

Managing users in ovpn-admin:
![ovpn-admin UI](https://raw.githubusercontent.com/danields966/ovpn-admin/master/img/ovpn-admin-users.png)

An example of dashboard made using ovpn-admin metrics:
![ovpn-admin metrics](https://raw.githubusercontent.com/danields966/ovpn-admin/master/img/ovpn-admin-metrics.png)

## Installation

### 1. Docker

There is a ready-to-use docker-compose config, so you can just change/add values you need and start it with [start.sh](https://github.com/danields966/ovpn-admin/blob/master/start.sh).

You can create it from copying example file:

    cp docker-compose.yaml.example docker-compose.yaml

Then find and replace all following variables in docker-compose.yaml:

* `YOUR_OPENVPN_SERVER_IP`: Public IP address of your OpenVPN server
* `YOUR_OPENVPN_SERVER_PORT`: Port of your OpenVPN server (you can set 1194 as default)
* `YOUR_OVPN_ADMIN_USER`: Login to access ovpn-admin via HTTP basic authentication
* `YOUR_OVPN_ADMIN_PORT`: Port to access ovpn-admin (you can set 80 as default)
* `YOUR_OVPN_ADMIN_PASSWORD_HASH`: Well, it's a bit complicated, but you need to choose a password and create an `apr1` hash for it. You can do it via command `openssl passwd -apr1 YOUR_PASSWORD` and you'll get string like that: `$apr1$fvM4f1vt$kQoXBas63UsUEJt4MaItS1`, then please double all `$` signs to avoid variable rendering, and you'll have something like `$$apr1$$fvM4f1vt$$kQoXBas63UsUEJt4MaItS1`

Requirements:
You need [Docker](https://docs.docker.com/get-docker/) and [docker-compose](https://docs.docker.com/compose/install/) installed.

Commands to execute:

```bash
git clone https://github.com/danields966/ovpn-admin.git
cd ovpn-admin
./start.sh
```

## Notes
* this tool uses external calls for `bash`, `coreutils` and `easy-rsa`, thus **Linux systems only are supported** at the moment.
* to enable additional password authentication provide `--auth` and `--auth.db="/etc/easyrsa/pki/users.db`" flags and install [openvpn-user](https://github.com/pashcovich/openvpn-user/releases/latest). This tool should be available in your `$PATH` and its binary should be executable (`+x`).
* master-replica synchronization does not work with `--storage.backend=kubernetes.secrets` - **WIP**
* additional password authentication does not work with `--storage.backend=kubernetes.secrets` -  **WIP**
* if you use `--ccd` and `--ccd.path="/etc/openvpn/ccd"` abd plan to use static address setup for users do not forget to provide `--ovpn.network="172.16.100.0/24"` with valid openvpn-server network 
* tested only with Openvpn-server versions 2.4 and 2.5 with only tls-auth mode
* not tested with EasyRsa version > 3.0.8
* status of users connections update every 28 second(*no need to ask why =)*)

## Usage

```
usage: ovpn-admin [<flags>]

Flags:
  --help                       show context-sensitive help (try also --help-long and --help-man)

  --listen.host="0.0.0.0"      host for ovpn-admin
  (or OVPN_LISTEN_HOST)

  --listen.port="8080"         port for ovpn-admin
  (or OVPN_LISTEN_PORT)

  --listen.base-url="/"        base URL for ovpn-admin web files
  (or $OVPN_LISTEN_BASE_URL)

  --role="master"              server role, master or slave
  (or OVPN_ROLE)

  --master.host="http://127.0.0.1"  
  (or OVPN_MASTER_HOST)       URL for the master server

  --master.basic-auth.user=""  user for master server's Basic Auth
  (or OVPN_MASTER_USER)
 
  --master.basic-auth.password=""  
  (or OVPN_MASTER_PASSWORD)   password for master server's Basic Auth

  --master.sync-frequency=600  master host data sync frequency in seconds
  (or OVPN_MASTER_SYNC_FREQUENCY)

  --master.sync-token=TOKEN    master host data sync security token
  (or OVPN_MASTER_TOKEN)

  --ovpn.network="172.16.100.0/24"  
  (or OVPN_NETWORK)           NETWORK/MASK_PREFIX for OpenVPN server

  --ovpn.server=HOST:PORT:PROTOCOL ...  
  (or OVPN_SERVER)            HOST:PORT:PROTOCOL for OpenVPN server
                               can have multiple values

  --ovpn.server.behindLB       enable if your OpenVPN server is behind Kubernetes
  (or OVPN_LB)                Service having the LoadBalancer type

  --ovpn.service="openvpn-external"  
  (or OVPN_LB_SERVICE)        the name of Kubernetes Service having the LoadBalancer
                               type if your OpenVPN server is behind it

  --mgmt=main=127.0.0.1:8989 ...  
  (or OVPN_MGMT)              ALIAS=HOST:PORT for OpenVPN server mgmt interface;
                               can have multiple values

  --metrics.path="/metrics"    URL path for exposing collected metrics
  (or OVPN_METRICS_PATH)

  --easyrsa.path="./easyrsa/"  path to easyrsa dir
  (or EASYRSA_PATH)

  --easyrsa.index-path="./easyrsa/pki/index.txt"  
  (or OVPN_INDEX_PATH)        path to easyrsa index file

  --ccd                        enable client-config-dir
  (or OVPN_CCD)

  --ccd.path="./ccd"           path to client-config-dir
  (or OVPN_CCD_PATH)

  --templates.clientconfig-path=""  
  (or OVPN_TEMPLATES_CC_PATH) path to custom client.conf.tpl

  --templates.ccd-path=""      path to custom ccd.tpl
  (or OVPN_TEMPLATES_CCD_PATH)

  --auth.password              enable additional password authorization
  (or OVPN_AUTH)

  --auth.db="./easyrsa/pki/users.db"
  (or OVPN_AUTH_DB_PATH)      database path for password authorization
  
  --log.level                  set log level: trace, debug, info, warn, error (default info)
  (or LOG_LEVEL)
  
  --log.format                 set log format: text, json (default text)
  (or LOG_FORMAT)
  
  --storage.backend            storage backend: filesystem, kubernetes.secrets (default filesystem)
  (or STORAGE_BACKEND)
 
  --version                    show application version
```

## Further information

Please feel free to use [issues](https://github.com/danields966/ovpn-admin/issues) and [discussions](https://github.com/danields966/ovpn-admin/discussions) to get help from maintainers & community.
