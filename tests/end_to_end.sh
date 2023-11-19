
set -e

make build


make server-sample &
sleep 3

# test upload single file
rm -f /tmp/testfile-out.txt
mkdir -p ./tmp
echo "testcontentfile!" > ./tmp/testfile.txt

./zig-out/bin/z-upload ./tmp/testfile.txt /tmp/testfile-out.txt@127.0.0.1:8000

expected_checksum=$(cat ./tmp/testfile.txt | cksum)

given_checksum=$(cat /tmp/testfile-out.txt | cksum)

if [ "$expected_checksum" != "$given_checksum" ]; then
    echo "Checksums do not match!"
    exit 1
fi

# test upload folder
rm -f /tmp/testfolder-*.txt
mkdir -p ./tmp
echo "testcontentfile!" > ./tmp/testfolder-1.txt
echo "testcontentfile2!" > ./tmp/testfolder-2.txt

./zig-out/bin/z-upload ./tmp/ /tmp/@127.0.0.1:8000

expected_checksum_f1=$(cat ./tmp/testfolder-1.txt | cksum)
given_checksum_f1=$(cat /tmp/testfolder-1.txt | cksum)

if [ "$expected_checksum_f1" != "$given_checksum_f1" ]; then
    echo "Checksums do not match!"
    exit 1
fi

expected_checksum_f2=$(cat ./tmp/testfolder-2.txt | cksum)
given_checksum_f2=$(cat /tmp/testfolder-2.txt | cksum)

if [ "$expected_checksum_f2" != "$given_checksum_f2" ]; then
    echo "Checksums do not match!"
    exit 1
fi

killall z-upload

echo "End to end tests successful"
