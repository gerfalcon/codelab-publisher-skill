#!/usr/bin/env bash
# post_process.sh — Inject copy-to-clipboard buttons into generated codelab HTML files.

set -euo pipefail

DOCS_DIR="${DOCS_DIR:-docs}"

if [ ! -d "$DOCS_DIR" ]; then
  echo "No docs directory found at $DOCS_DIR. Skipping post-processing."
  exit 0
fi

# The JS script we want to inject
JS_SCRIPT='<script>
(function() {
  document.querySelectorAll("pre > code").forEach(function(codeBlock) {
    var pre = codeBlock.parentNode;
    pre.style.position = "relative";
    
    var button = document.createElement("button");
    button.className = "copy-code-button";
    button.type = "button";
    button.innerText = "Copy";
    
    button.style.position = "absolute";
    button.style.top = "8px";
    button.style.right = "8px";
    button.style.border = "none";
    button.style.borderRadius = "4px";
    button.style.padding = "4px 8px";
    button.style.fontSize = "12px";
    button.style.backgroundColor = "#f1f3f4";
    button.style.color = "#3c4043";
    button.style.cursor = "pointer";
    button.style.zIndex = "10";
    button.style.boxShadow = "0 1px 2px 0 rgba(60,64,67,0.3), 0 1px 3px 1px rgba(60,64,67,0.15)";
    button.style.fontFamily = "\"Roboto\", sans-serif";
    button.style.transition = "background-color 0.2s, color 0.2s";

    button.addEventListener("mouseenter", function() {
      button.style.backgroundColor = "#e8eaed";
    });
    button.addEventListener("mouseleave", function() {
      button.style.backgroundColor = "#f1f3f4";
    });
    
    button.addEventListener("click", function() {
      var code = codeBlock.innerText;
      navigator.clipboard.writeText(code).then(function() {
        button.innerText = "Copied!";
        button.style.backgroundColor = "#e6f4ea";
        button.style.color = "#137333";
        
        setTimeout(function() {
          button.innerText = "Copy";
          button.style.backgroundColor = "#f1f3f4";
          button.style.color = "#3c4043";
        }, 2000);
      }).catch(function(err) {
        console.error("Failed to copy text: ", err);
        button.innerText = "Error";
      });
    });
    
    pre.appendChild(button);
  });
})();
</script>'

# Find all index.html files under docs/ and post-process them
find "$DOCS_DIR" -name "index.html" | while read -r html_file; do
  # Check if the copy script is already injected
  if grep -q "copy-code-button" "$html_file"; then
    echo "  Already post-processed: $html_file"
    continue
  fi

  echo "  Injecting copy-to-clipboard feature into: $html_file"
  
  # Use Node to perform the file edit in a cross-platform way
  node -e "
const fs = require('fs');
const filePath = process.argv[1];
const script = process.argv[2];
let content = fs.readFileSync(filePath, 'utf8');
if (content.includes('</body>')) {
  content = content.replace('</body>', script + '\n</body>');
  fs.writeFileSync(filePath, content, 'utf8');
}
" "$html_file" "$JS_SCRIPT"
done

echo "Post-processing complete."
