
set -e

make build


make server-sample &
sleep 3

rm -f /tmp/testfile-out.txt
mkdir -p ./tmp
echo "testcontentfile!" > ./tmp/testfile.txt

./zig-out/bin/z-upload -client ./tmp/testfile.txt /tmp/testfile-out.txt@127.0.0.1:8000

expected_checksum=$(cat ./tmp/testfile.txt | cksum)

given_checksum=$(cat /tmp/testfile-out.txt | cksum)

if [ "$expected_checksum" != "$given_checksum" ]; then
    echo "Checksums do not match!"
    exit 1
fi
