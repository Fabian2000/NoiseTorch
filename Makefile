NAME_SUFFIX=
WEBSITE_URL=https://github.com/Fabian2000/NoiseTorch

VERSION := $(shell git describe --tags)

dev: rnnoise
	mkdir -p bin/
	go generate
	go build -ldflags '-X main.nameSuffix=${NAME_SUFFIX}_(dev) -X main.version=${VERSION} -X main.websiteURL=${WEBSITE_URL}' -o bin/noisetorch
release: rnnoise
	mkdir -p bin/
	mkdir -p tmp/NoiseTorch_x64_${VERSION}/

	cp assets/icon/noisetorch.png tmp/NoiseTorch_x64_${VERSION}/
	cp assets/noisetorch.desktop tmp/NoiseTorch_x64_${VERSION}/
	cp c/ladspa/rnnoise_ladspa.so tmp/NoiseTorch_x64_${VERSION}/nt-filter.so
	cp install.sh tmp/NoiseTorch_x64_${VERSION}/
	chmod +x tmp/NoiseTorch_x64_${VERSION}/install.sh

	go generate
	CGO_ENABLED=0 GOOS=linux go build -trimpath -tags release -a -ldflags '-s -w -extldflags "-static" -X main.nameSuffix=${NAME_SUFFIX} -X main.version=${VERSION} -X main.distribution=selfbuilt -X main.websiteURL=${WEBSITE_URL}' .
	mv noisetorch tmp/NoiseTorch_x64_${VERSION}/
	cd tmp/; \
	tar cvzf ../bin/NoiseTorch_x64_${VERSION}.tgz .
	rm -rf tmp/
rnnoise:
	git submodule update --init --recursive
	$(MAKE) -C c/ladspa
