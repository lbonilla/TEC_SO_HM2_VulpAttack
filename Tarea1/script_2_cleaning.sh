# Cleanup
echo
echo "[+] Cleaning up..."
kill $ATTACK_PID 2>/dev/null
kill $VULP_PID 2>/dev/null
rm -f evil_input.txt
unlink /tmp/XYZ 2>/dev/null

echo "Done!"