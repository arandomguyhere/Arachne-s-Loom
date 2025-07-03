#!/bin/bash

# TShark Challenge I: Teamwork Analysis Script
# This script analyzes the teamwork.pcap file to extract domains, IPs, and other artifacts

echo "=== TShark Challenge I: Teamwork Analysis ==="
echo "Starting analysis of teamwork.pcap..."
echo

# Check if pcap file exists
if [ ! -f "teamwork.pcap" ]; then
    echo "Error: teamwork.pcap not found in current directory"
    echo "Please ensure you're in the correct directory and the file exists."
    exit 1
fi

echo "1. BASIC PCAP INFORMATION"
echo "========================="
echo "File: teamwork.pcap"
echo "Basic statistics:"
tshark -r teamwork.pcap -q -z io,stat,0
echo

echo "2. PROTOCOL HIERARCHY"
echo "====================="
tshark -r teamwork.pcap -q -z io,phs
echo

echo "3. EXTRACTING DOMAINS AND URLS"
echo "==============================="

echo "DNS Queries:"
echo "------------"
tshark -r teamwork.pcap -Y "dns.flags.response == 0" -T fields -e dns.qry.name | sort | uniq | grep -v "^$"
echo

echo "HTTP Hosts:"
echo "-----------"
tshark -r teamwork.pcap -Y "http.request" -T fields -e http.host | sort | uniq | grep -v "^$"
echo

echo "HTTP URLs:"
echo "----------"
tshark -r teamwork.pcap -Y "http.request" -T fields -e http.host -e http.request.uri | awk '{if($1 && $2) print "http://" $1 $2}' | sort | uniq
echo

echo "4. SSL/TLS SERVER NAMES"
echo "======================="
tshark -r teamwork.pcap -Y "ssl.handshake.type == 1" -T fields -e ssl.handshake.extensions_server_name | sort | uniq | grep -v "^$"
echo

echo "5. ALL UNIQUE DOMAINS (Combined)"
echo "================================"
{
    tshark -r teamwork.pcap -Y "dns.flags.response == 0" -T fields -e dns.qry.name
    tshark -r teamwork.pcap -Y "http.request" -T fields -e http.host
    tshark -r teamwork.pcap -Y "ssl.handshake.type == 1" -T fields -e ssl.handshake.extensions_server_name
} | sort | uniq | grep -v "^$"
echo

echo "6. IP ADDRESSES"
echo "==============="
echo "Destination IPs:"
tshark -r teamwork.pcap -T fields -e ip.dst | sort | uniq | grep -v "^$"
echo

echo "Source IPs:"
tshark -r teamwork.pcap -T fields -e ip.src | sort | uniq | grep -v "^$"
echo

echo "7. EMAIL ADDRESSES"
echo "=================="
echo "Searching for email patterns in HTTP POST data:"
tshark -r teamwork.pcap -Y "http.request.method == POST" -T fields -e http.file_data | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort | uniq | grep -v "^$"

echo "Searching for email patterns in form data:"
tshark -r teamwork.pcap -Y "http.request.method == POST" -T fields -e urlencoded-form.key -e urlencoded-form.value | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort | uniq | grep -v "^$"

echo "Searching for email patterns in all HTTP traffic:"
tshark -r teamwork.pcap -Y "http" -T fields -e http.file_data | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort | uniq | grep -v "^$"

echo "Searching for email patterns in packet data:"
tshark -r teamwork.pcap -T fields -e data.text | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort | uniq | grep -v "^$"

echo "Searching for email patterns in DNS queries:"
tshark -r teamwork.pcap -Y "dns" -T fields -e dns.qry.name | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort | uniq | grep -v "^$"

echo "Examining POST request content in detail:"
echo "========================================="
echo "POST to /inc/login.php:"
tshark -r teamwork.pcap -Y "http.request.method == POST and http.request.uri contains \"login.php\"" -T fields -e frame.number -e http.file_data
echo

echo "POST to /inc/visit.php:"
tshark -r teamwork.pcap -Y "http.request.method == POST and http.request.uri contains \"visit.php\"" -T fields -e frame.number -e http.file_data
echo

echo "All POST request data:"
tshark -r teamwork.pcap -Y "http.request.method == POST" -T fields -e frame.number -e http.request.uri -e http.file_data
echo

echo "8. DETAILED HTTP ANALYSIS"
echo "========================="
echo "HTTP Requests with full details:"
tshark -r teamwork.pcap -Y "http.request" -T fields -e frame.number -e ip.src -e ip.dst -e http.host -e http.request.method -e http.request.uri -e http.user_agent | while read line; do
    if [ ! -z "$line" ]; then
        echo "  $line"
    fi
done
echo

echo "9. SUSPICIOUS PATTERNS"
echo "======================"
echo "Looking for potential phishing indicators:"
echo "Domains with common service names:"
tshark -r teamwork.pcap -Y "dns.flags.response == 0" -T fields -e dns.qry.name | grep -iE "(google|microsoft|amazon|apple|paypal|bank|secure|login|account)" | sort | uniq | while read domain; do
    if [ ! -z "$domain" ]; then
        echo "  $domain (potential impersonation)"
    fi
done
echo

echo "10. DEFANGED OUTPUT EXAMPLES"
echo "============================"
echo "Remember to defang your final answers:"
echo "URLs: http://example[.]com/path"
echo "IPs: 192[.]168[.]1[.]1"
echo "Emails: user[at]domain[.]com"
echo

echo "=== ANALYSIS COMPLETE ==="
echo "Next steps:"
echo "1. Take the domains found above and check them on VirusTotal"
echo "2. Look for the one marked as malicious/suspicious"
echo "3. Extract the required information and defang it"
echo "4. Cross-reference with the IP addresses and email patterns found"
echo

echo "=== QUICK ANSWERS ==="
echo "Malicious Domain: www.paypal.com4uswebappsresetaccountrecovery.timeseaways.com"
echo "IP Address (defanged): 184[.]154[.]127[.]226"
echo "Service impersonated: PayPal"
echo "Email address: Check POST data above"
echo

# Create a summary file
echo "Creating summary file: analysis_summary.txt"
echo "=== DOMAIN SUMMARY ===" > analysis_summary.txt
(
    tshark -r teamwork.pcap -Y "dns.flags.response == 0" -T fields -e dns.qry.name
    tshark -r teamwork.pcap -Y "http.request" -T fields -e http.host
    tshark -r teamwork.pcap -Y "ssl.handshake.type == 1" -T fields -e ssl.handshake.extensions_server_name
) | sort | uniq | while read domain; do
    if [ ! -z "$domain" ]; then
        echo "$domain" >> analysis_summary.txt
    fi
done

echo "" >> analysis_summary.txt
echo "=== IP ADDRESSES ===" >> analysis_summary.txt
tshark -r teamwork.pcap -T fields -e ip.dst | sort | uniq | while read ip; do
    if [ ! -z "$ip" ]; then
        echo "$ip" >> analysis_summary.txt
    fi
done

echo "Summary saved to analysis_summary.txt"
