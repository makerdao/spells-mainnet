FROM makerdao/dapphub-tools

WORKDIR /home/maker/spells-mainnet
COPY .git .git
COPY archive archive
COPY lib lib
COPY src src
COPY Makefile Makefile
COPY addresses.json addresses.json
COPY test-dssspell.sh test-dssspell.sh

RUN sudo chown -R maker:maker /home/maker/spells-mainnet

CMD /bin/bash -c "export PATH=/home/maker/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && ./test-dssspell.sh"


