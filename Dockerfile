FROM kalilinux/kali-rolling:latest

# Metadata
LABEL maintainer="Thierry Braga"
LABEL description="Kali Linux with MCP Server for Penetration Testing"
LABEL version="1.0"

# Evitar prompts interativos durante instalação
ENV DEBIAN_FRONTEND=noninteractive
ENV GOPATH=/root/go
ENV PATH=$PATH:/root/go/bin

# Atualizar sistema e instalar ferramentas essenciais
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    nmap \
    masscan \
    netcat-traditional \
    netdiscover \
    arp-scan \
    nikto \
    dirb \
    gobuster \
    wfuzz \
    dnsenum \
    fierce \
    hydra \
    medusa \
    john \
    hashcat \
    patator \
    sqlmap \
    wpscan \
    commix \
    metasploit-framework \
    exploitdb \
    aircrack-ng \
    reaver \
    wireshark \
    tcpdump \
    ettercap-text-only \
    enum4linux \
    smbclient \
    nbtscan \
    snmp \
    curl \
    tor \
    torsocks \
    wget \
    git \
    vim \
    nano \
    tmux \
    screen \
    python3 \
    python3-pip \
    python3-venv \
    python3-requests \
    nodejs \
    npm \
    build-essential \
    golang-go \
    wordlists \
    seclists \
    && for pkg in \
    golang-go \
    kali-tools-information-gathering \
    kali-tools-web \
    kali-tools-passwords \
    kali-tools-wireless \
    kali-tools-exploitation \
    kali-tools-sniffing-spoofing \
    kali-tools-post-exploitation \
    kali-tools-forensics \
    awscli \
    zaproxy \
    burpsuite \
    zenmap \
    theharvester \
    recon-ng \
    maltego \
    dnsrecon \
    whatweb \
    wafw00f \
    dmitry \
    unicornscan \
    spiderfoot \
    smtp-user-enum \
    snmp-check \
    sslscan \
    sslstrip \
    ike-scan \
    amap \
    lbd \
    sublist3r \
    cloudbrute \
    assetfinder \
    gau \
    waybackurls \
    massdns \
    paramspider \
    arjun \
    dirbuster \
    joomscan \
    cmsmap \
    xsstrike \
    beef-xss \
    skipfish \
    arachni \
    davtest \
    droopescan \
    nosqlmap \
    brutespray \
    ncrack \
    cewl \
    crunch \
    ophcrack \
    wifite \
    bully \
    kismet \
    pixiewps \
    fern-wifi-cracker \
    mdk4 \
    airgeddon \
    wifi-pumpkin3 \
    armitage \
    routersploit \
    set \
    bettercap \
    driftnet \
    mitmf \
    yersinia \
    mimikatz \
    powershell-empire \
    weevely \
    lazagne \
    linux-exploit-suggester \
    windows-exploit-suggester \
    autopsy \
    volatility \
    binwalk \
    foremost \
    ghidra \
    radare2 \
    apktool \
    dex2jar \
    binutils \
    exiftool \
    amass \
    subfinder \
    ffuf \
    feroxbuster \
    dirsearch \
    nuclei \
    httpx \
    crackmapexec \
    responder \
    impacket-scripts \
    bloodhound \
    ldapdomaindump \
    dalfox \
    ; do apt-get install -y "$pkg" || true; done \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN if command -v go >/dev/null 2>&1; then go install github.com/hahwul/dalfox/v2@latest && cp /root/go/bin/dalfox /usr/local/bin/dalfox; fi
RUN apt-get update && apt-get install -y \
    arachni \
    cmsmap \
    droopescan \
    gau \
    waybackurls \
    lazagne \
    mitmf \
    nosqlmap \
    routersploit \
    volatility \
    wifi-pumpkin3 \
    windows-exploit-suggester \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* || true
RUN if command -v go >/dev/null 2>&1; then \
    if ! command -v gau >/dev/null 2>&1; then go install github.com/lc/gau/v2/cmd/gau@latest && cp /root/go/bin/gau /usr/local/bin/gau; fi && \
    if ! command -v waybackurls >/dev/null 2>&1; then go install github.com/tomnomnom/waybackurls@latest && cp /root/go/bin/waybackurls /usr/local/bin/waybackurls; fi; \
    fi
RUN if ! command -v lazagne >/dev/null 2>&1; then \
    git clone --depth 1 https://github.com/AlessandroZ/LaZagne.git /opt/LaZagne && \
    entry=""; \
    if [ -f /opt/LaZagne/LaZagne.py ]; then entry="/opt/LaZagne/LaZagne.py"; fi; \
    if [ -z "$entry" ] && [ -f /opt/LaZagne/laZagne.py ]; then entry="/opt/LaZagne/laZagne.py"; fi; \
    if [ -z "$entry" ]; then entry="$(find /opt/LaZagne -maxdepth 2 -name "*Zagne*.py" | head -n 1)"; fi; \
    chmod +x "$entry" && ln -s "$entry" /usr/local/bin/lazagne; \
    fi
RUN if ! command -v rsf >/dev/null 2>&1; then pip3 install --break-system-packages git+https://github.com/threat9/routersploit.git; fi
RUN if [ -f /usr/bin/rsf.py ] && ! command -v rsf >/dev/null 2>&1; then ln -s /usr/bin/rsf.py /usr/local/bin/rsf; fi
RUN if ! command -v python2 >/dev/null 2>&1; then apt-get update && apt-get install -y python2 python2-dev python2-minimal && apt-get clean && rm -rf /var/lib/apt/lists/*; fi
RUN if ! command -v pip2 >/dev/null 2>&1; then curl -sS https://bootstrap.pypa.io/pip/2.7/get-pip.py -o /tmp/get-pip.py && python2 /tmp/get-pip.py && rm /tmp/get-pip.py; fi
RUN if ! command -v arachni >/dev/null 2>&1; then \
    arachni_url="$(curl -s https://api.github.com/repos/Arachni/arachni/releases/latest | tr ',' '\n' | grep browser_download_url | grep 'linux-x86_64.tar.gz\"' | cut -d '\"' -f4 | head -n 1)"; \
    if [ -z "$arachni_url" ]; then arachni_url="https://github.com/Arachni/arachni/releases/download/v1.6.1.3/arachni-1.6.1.3-0.6.1.1-linux-x86_64.tar.gz"; fi; \
    mkdir -p /opt/arachni && \
    curl -L "$arachni_url" -o /tmp/arachni.tar.gz && \
    tar -xzf /tmp/arachni.tar.gz -C /opt/arachni --strip-components 1 && \
    rm /tmp/arachni.tar.gz && \
    if [ -f /opt/arachni/bin/arachni ]; then ln -sf /opt/arachni/bin/arachni /usr/local/bin/arachni; fi && \
    if [ -f /opt/arachni/bin/arachni_reporter ]; then ln -sf /opt/arachni/bin/arachni_reporter /usr/local/bin/arachni_reporter; fi && \
    if [ -f /opt/arachni/bin/arachni_web ]; then ln -sf /opt/arachni/bin/arachni_web /usr/local/bin/arachni_web; fi && \
    if [ -f /opt/arachni/bin/arachni_rpcd ]; then ln -sf /opt/arachni/bin/arachni_rpcd /usr/local/bin/arachni_rpcd; fi; \
    fi
RUN if ! command -v cmsmap >/dev/null 2>&1; then \
    git clone --depth 1 https://github.com/Dionach/CMSmap.git /opt/CMSmap && \
    chmod +x /opt/CMSmap/cmsmap.py && \
    printf '#!/bin/bash\npython3 /opt/CMSmap/cmsmap.py \"$@\"\n' > /usr/local/bin/cmsmap && chmod +x /usr/local/bin/cmsmap; \
    fi
RUN if ! command -v droopescan >/dev/null 2>&1; then pip3 install --break-system-packages droopescan; fi
RUN if ! command -v nosqlmap >/dev/null 2>&1; then \
    git clone --depth 1 https://github.com/codingo/NoSQLMap.git /opt/NoSQLMap && \
    if [ -f /opt/NoSQLMap/requirements.txt ]; then pip2 install -r /opt/NoSQLMap/requirements.txt; fi && \
    printf '#!/bin/bash\npython2 /opt/NoSQLMap/nosqlmap.py \"$@\"\n' > /usr/local/bin/nosqlmap && chmod +x /usr/local/bin/nosqlmap; \
    fi
RUN if ! command -v mitmf >/dev/null 2>&1; then \
    git clone --depth 1 https://github.com/byt3bl33d3r/MITMf.git /opt/MITMf && \
    pip2 install -r /opt/MITMf/requirements.txt || true && \
    printf '#!/bin/bash\npython2 /opt/MITMf/mitmf.py \"$@\"\n' > /usr/local/bin/mitmf && chmod +x /usr/local/bin/mitmf; \
    fi
RUN if ! command -v volatility >/dev/null 2>&1; then \
    git clone --depth 1 https://github.com/volatilityfoundation/volatility.git /opt/volatility && \
    pip2 install -r /opt/volatility/requirements.txt || true && \
    printf '#!/bin/bash\npython2 /opt/volatility/vol.py \"$@\"\n' > /usr/local/bin/volatility && chmod +x /usr/local/bin/volatility; \
    fi
RUN if ! command -v windows-exploit-suggester >/dev/null 2>&1; then \
    git clone --depth 1 https://github.com/AonCyberLabs/Windows-Exploit-Suggester.git /opt/windows-exploit-suggester && \
    printf '#!/bin/bash\npython2 /opt/windows-exploit-suggester/windows-exploit-suggester.py \"$@\"\n' > /usr/local/bin/windows-exploit-suggester && chmod +x /usr/local/bin/windows-exploit-suggester; \
    fi
RUN if ! command -v wifi-pumpkin3 >/dev/null 2>&1; then \
    git clone --depth 1 https://github.com/P0cL4bs/wifipumpkin3.git /opt/wifi-pumpkin3 && \
    pip3 install --break-system-packages -r /opt/wifi-pumpkin3/requirements.txt || true && \
    pip3 install --break-system-packages -e /opt/wifi-pumpkin3 || true && \
    rm -f /usr/local/bin/wifi-pumpkin3 && printf '#!/bin/bash\npython3 -m wifipumpkin3 \"$@\"\n' > /usr/local/bin/wifi-pumpkin3 && chmod +x /usr/local/bin/wifi-pumpkin3; \
    fi

# Criar diretórios de trabalho
RUN mkdir -p /opt/mcp-server \
    /root/wordlists \
    /root/reports \
    /root/scripts \
    /root/targets \
    /root/nmap-results

RUN dpkg -s wordlists >/dev/null 2>&1 || (apt-get update && apt-get install -y wordlists && apt-get clean && rm -rf /var/lib/apt/lists/*)

# Copiar wordlists para local acessível
RUN cp -r /usr/share/wordlists/* /root/wordlists/ 2>/dev/null || true && \
    gunzip /root/wordlists/*.gz 2>/dev/null || true && \
    chmod -R a+rX /usr/share/wordlists /root/wordlists

# Removido pip install devido ao PEP 668; dependências Python via apt

# Copiar MCP server e scripts
# Ajustado para a estrutura atual do repositório
COPY package.json /opt/mcp-server/package.json
COPY server.js /opt/mcp-server/server.js
COPY scripts/ /root/scripts/
COPY skills/ /root/skills/

# Instalar dependências Node.js do MCP server
WORKDIR /opt/mcp-server
RUN npm install

# Tornar scripts executáveis
RUN chmod +x /root/scripts/*.sh 2>/dev/null || true

# Configurar metasploit database
RUN msfdb init 2>/dev/null || true

# Criar script de inicialização
RUN echo '#!/bin/bash\n\
echo "================================================="\n\
echo "  Kali Linux MCP Pentest Environment"\n\
echo "  Version: 1.0"\n\
echo "================================================="\n\
echo ""\n\
echo "Available Tools:"\n\
echo "  - nmap, masscan (Network scanning)"\n\
echo "  - hydra, medusa (Brute force)"\n\
echo "  - sqlmap, wpscan (Web testing)"\n\
echo "  - metasploit (Exploitation)"\n\
echo "  - aircrack-ng (Wireless)"\n\
echo ""\n\
echo "MCP Server: http://localhost:3000"\n\
echo "Reports: /root/reports"\n\
echo "Scripts: /root/scripts"\n\
echo "================================================="\n\
echo ""\n\
# Iniciar MCP server em background\n\
cd /opt/mcp-server && node server.js &\n\
# Manter container rodando\n\
exec /bin/bash\n\
' > /root/start.sh && chmod +x /root/start.sh

WORKDIR /root

# Expor porta do MCP server
EXPOSE 3000

# Comando padrão
CMD ["/root/start.sh"]
