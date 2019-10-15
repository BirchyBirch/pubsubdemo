if (test-path ".build"){
    Remove-Item ".build" -Force -Recurse
}
docker build --no-cache -t localtest:testing . 
docker rm dummy
docker create -ti --name dummy localtest:testing cmd
docker cp dummy:c:/src/art/ ./
# Compress-Archive '.\\.build\website' ".\\.build\website.zip"