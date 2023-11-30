# z-upload

todo 
compress decompress https://ziglang.org/documentation/0.11.0/std/src/std/compress/zlib.zig.html#L179

todo retry, but with buffer (client, serv) 65000

## Benchmark

Filesize 1.350 GB

- z-upload, 50 KB chunk: 11.6 seconds
- z-upload, 100 KB chunk: 11.7 seconds
- z-upload, 200 KB chunk: 11.5 seconds
- z-upload, 400 KB chunk: 11.6 seconds
- z-upload, 1 MB chunk: 11.7 seconds
- vsftpd: 13 seconds
- sftp: 38 seconds

