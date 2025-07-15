#!/bin/bash

#ai : automated-image

# SHELL SCRIPT TO PROPERLY STORE IMAGES IN /img/ folder and automatically define the filepath
# in a markdown -> target : all markdown files in current directory

# initial state:
# ![description-1](image.png)
# ![description-2](image-1.png)
# ![description-3](image-2.png)
# ![description-4](image-3.png)

# final state:
# ![description-1](./img/description-1.png)
# ![description-2](./img/description-2.png)
# ![description-3](./img/description-3.png)
# ![description-4](./img/description-4.png)

# Create ./img directory if it doesn't exist
mkdir -p img

# Process all .md files in current directory
for mdfile in *.md; do
  echo "📄 Processing $mdfile..."

  # Extract all alt texts (assumed to be the desired file name)
  grep -oP '!\[\K[^\]]+(?=\]\([^)]*\.png\))' "$mdfile" | while read -r alttext; do
    # Find the current image file path
    current_img=$(grep -oP "!\[$alttext\]\(\K[^)]+" "$mdfile")

    # Skip if no match found
    if [[ -z "$current_img" ]]; then
      echo "  ❌ No image found for alt: $alttext"
      continue
    fi

    # Clean current_img (remove ./ prefix if exists)
    clean_current_img="${current_img#./}"

    # Define target image path
    new_img="img/$alttext.png"

    # Skip if already correct
    if [[ "$clean_current_img" == "$new_img" ]]; then
      echo "  ✅ $new_img already in correct place"
      continue
    fi

    # Perform move if source exists
    if [[ -f "$clean_current_img" ]]; then
      echo "  🔄 Moving $clean_current_img -> $new_img"
      mv "$clean_current_img" "$new_img"
    else
      echo "  ⚠️  Image not found: $clean_current_img"
    fi

    # Update markdown line
    sed -i.bak -E "s|!\[$alttext\]\([^)]*\.png\)|![$alttext](./$new_img)|g" "$mdfile"

    # Delete backup file after successful change
    rm -f "${mdfile}.bak"
  done
done

echo "✅ Done. Images renamed, moved, and markdown updated."
