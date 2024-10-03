# /// script
# dependencies = [
#   "beautifulsoup4",
#   "lxml",
# ]
# ///
from bs4 import BeautifulSoup
import sys

if len(sys.argv) != 2:
    print("Usage: python add_versions.py <input_file>")
    sys.exit(1)

# Define the file name of the existing HTML file
input_file = sys.argv[1]

# Read the contents of the existing HTML file
with open(input_file, 'r', encoding='utf-8') as file:
    html_content = file.read()

# Parse the HTML content with BeautifulSoup
soup = BeautifulSoup(html_content, 'lxml')

# links:
links = {
    "Current stable (Brick v1.4)": "/",
    "Brick v1.4": "/1.4",
    "Brick v1.3": "/1.3",
}

select = soup.new_tag('select', {'id': 'brickVersionDropdown'})
# create options
for index,(text, href) in enumerate(links.items()):
    if index == 0:
        option = soup.new_tag('option', value=href, selected='selected')
    else:
        option = soup.new_tag('option', value=href)
    option.string = text
    select.append(option)
# add the brickVersionDropdown id to the select tag
select['id'] = 'brickVersionDropdown'
label = soup.new_tag('label', {'for': 'brickVersionDropdown'})
label.string = 'Select Brick version:'
# put the label before the select tag and put them in their own div
select_div = soup.new_tag('div')
select_div.append(label)
select_div.append(select)


# when the option is selected, redirect to the selected version
script = soup.new_tag('script')
script.string = """
document.addEventListener('DOMContentLoaded', function() {
    // Check if there is a saved version in localStorage
    var savedVersion = localStorage.getItem('selectedBrickVersion');
    if (savedVersion) {
        document.getElementById('brickVersionDropdown').value = savedVersion;
    }

    document.getElementById('brickVersionDropdown').onchange = function() {
        // Save the selected version in localStorage
        localStorage.setItem('selectedBrickVersion', this.value);
        // Redirect to the selected version
        window.location.href = this.value;
    }
});"""

# Add the script to the end of the document
soup.head.append(script)

# Find the search container to insert the dropdown menu above it
search_container = soup.find('div', class_='search-container')
if search_container:
    search_container.append(select_div)

    # Write the modified content back to a new file or overwrite the existing one
    with open(sys.argv[1], 'w', encoding='utf-8') as file:
        file.write(str(soup))

    print(f"Dropdown menu added successfully to {sys.argv[1]}.")
else:
    print("Could not find the search container in the HTML file.")
    sys.exit(1)
