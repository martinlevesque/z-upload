# z-upload

Lightweight TCP client-server file uploader written in zig, mainly for learning purpose.

## Environment variables

- `Z_UPLOAD_HOST_PORT` (Client only): default host-port address to use.
- `Z_UPLOAD_AUTH_KEY` (Server, Client): Authentication key. When the client requests the server, if it is set, it will pass an auth key to be verified by the server for access authentication.

## Booting the server

```bash
Z_UPLOAD_AUTH_KEY=hello z-upload -server 0.0.0.0:8000
```

or `make server`.

## Client upload

For sending a local file "./tmp/testfile.txt" to the remote server in folder /tmp/

```bash
Z_UPLOAD_AUTH_KEY=hello Z_UPLOAD_HOST_PORT=127.0.0.1:8000 z-upload ./tmp/testfile.txt /tmp/
```


## Benchmark

Sample Filesize 1.350 GB

- z-upload: 11.5 seconds
- vsftpd: 13 seconds
- sftp: 38 seconds

