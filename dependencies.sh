mkdir tools

GO111MODULE=on go get -v github.com/projectdiscovery/naabu/cmd/naabu
alias naabu="~/go/bin/naabu"
cd ~/tools
git clone https://github.com/blechschmidt/massdns.git
cd massdns
make 
alias massdns="~/massdns/bin/massdns"
cd ~/

export GO111MODULE=on
go get -v github.com/OWASP/Amass/v3/...
alias amass="~/go/bin/amass"
