### How to build image (Debian Bookworm example).
```
docker build \
  --build-arg BUILD_NUMBER=69 \
  --file .github/docker/debian/bookworm/amd64/Dockerfile \
  --progress=plain \
  --tag artifacts:latest \
  --ulimit nofile=1024000:1024000 \
  .
```

### How to dump artifacts from image to current directory.
```
docker save artifacts:latest | tar --ignore-command-error --strip-components=2 --to-command='tar -vxf -' -xf -
```
