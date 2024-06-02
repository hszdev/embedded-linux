from flask import Flask, render_template_string, send_from_directory
import os
import json
import random
import argparse

app = Flask(__name__)
IMAGE_FOLDER = '/home/emli/embedded-linux/wildlife/photos'


template = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Image List</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f0f0f0;
            display: flex; /* Use flexbox for layout */
        }

        h1 {
            text-align: center;
            margin-top: 20px;
            color: #333;
        }

        /* Main container for images and logs */
        .container {
            display: flex;
            flex-direction: row;
            justify-content: space-between;
            width: calc(100% - 40px); /* Adjusted width */
            padding: 20px;
            margin: 20px; /* Added margin */
        }

        /* Container for images */
        .image-container {
            flex: 1; /* Take remaining space */
        }

        .image-list {
            list-style: none;
            padding: 0;
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 20px;
            justify-items: center;
            margin: 0;
        }

        .image-item {
            position: relative;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease;
        }

        .image-item:hover {
            transform: translateY(-5px);
        }

        .image-item img {
            width: 100%;
            height: auto;
            display: block;
        }

        .timestamp {
            position: absolute;
            top: 5px; /* Adjusted position to appear above the image card */
            left: 50%;
            transform: translateX(-50%);
            background-color: rgba(255, 255, 255, 0.7);
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 14px;
            color: #333;
            opacity: 0; /* Initially hidden */
            transition: opacity 0.3s ease;
            z-index: 1; /* Ensure it's above the image */
        }

        .image-item:hover .timestamp {
            opacity: 1; /* Show timestamp on hover */
        }

        /* Modal styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 80%; /* Adjusted width */
            max-width: 800px; /* Limit maximum width */
            max-height: 80%;
            background-color: #fff;
            border-radius: 8px;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.2);
            padding: 20px;
            text-align: center;
            animation: fadeIn 0.3s ease-out;
        }

        .modal-content img {
            max-width: 100%;
            height: auto;
            display: block;
            border-radius: 8px;
            margin-bottom: 10px;
        }

        .modal-background {
            display: none;
            position: fixed;
            z-index: 999;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.8); /* Semi-transparent black */
        }

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        /* Log container */
        .log-container {
            flex: 0 0 25%; /* Take 25% of the space */
            background-color: #ffffff;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            padding: 20px;
            overflow-y: auto; /* Enable vertical scrolling */
            max-height: calc(100vh - 80px); /* Set max height to prevent window expansion */
        }

        .log-item {
            margin-bottom: 10px;
            padding-bottom: 10px;
            border-bottom: 1px solid #ddd;
        }
    </style>
</head>
<body>
    <h1>Images</h1>
    <div class="container">
        <div class="image-container">
            <ul class="image-list">
                {% for image, json_file in image_json_pairs %}
                    <li class="image-item">
                        <div class="timestamp">{{ json_file["Create Date"] }}</div>
                        <img src="/images/{{ image }}" onclick="openModal('{{ image }}')">
                    </li>
                {% endfor %}
            </ul>
        </div>

        <!-- Log container -->
        <div class="log-container">
            <h2>Logs</h2>
            <div class="log-list">
                {% for log in logs %}
                    <div class="log-item">{{ log }}</div>
                {% endfor %}
            </div>
        </div>
    </div>

    <!-- Modal -->
    <div id="myModal" class="modal">
        <div class="modal-content">
            <img id="modalImg">
            <div id="modalMetadata" class="metadata-container"></div> <!-- Metadata display -->
        </div>
    </div>

    <!-- Modal background -->
    <div id="modalBackground" class="modal-background" onclick="closeModal()"></div>

    <script>
        // Open the modal with the clicked image
        var allMetadata = JSON.parse('{{ image_json_pairs | tojson | safe }}');

        function openModal(image) {
            var modal = document.getElementById('myModal');
            var modalImg = document.getElementById('modalImg');
            var modalMetadata = document.getElementById('modalMetadata');
            var imageIndex = image.split('_')[0]; // Extracting image index from filename
            modal.style.display = 'block'; // Display the modal
            document.getElementById('modalBackground').style.display = 'block'; // Display the modal background
            modalImg.src = '/images/' + image;

            // Retrieve and display metadata
            metadata = null;
            for (var i = 0; i < allMetadata.length; i++) {
                    if (allMetadata[i][0] === image) {
                        metadata = allMetadata[i][1];
                        break;
                    }
            }

            var metadataHTML = '<h2>Metadata</h2><div class="metadata-container">';
            for (var key in metadata) {
                if (typeof metadata[key] === 'object') {
                    metadataHTML += '<div class="metadata-item"><strong>' + key + ':</strong>';
                    for (var nestedKey in metadata[key]) {
                        metadataHTML += '<div class="metadata-item"><strong>' + nestedKey + ':</strong> ' + metadata[key][nestedKey] + '</div>';
                    }
                    metadataHTML += '</div>';
                }
                else {
                    metadataHTML += '<div class="metadata-item"><strong>' + key + ':</strong> ' + metadata[key] + '</div>';
                }
            }
            
            metadataHTML += '</div>';
            modalMetadata.innerHTML = metadataHTML;
        }

        // Close the modal
        function closeModal() {
            var modal = document.getElementById('myModal');
            modal.style.display = 'none'; // Hide the modal
            document.getElementById('modalBackground').style.display = 'none'; // Hide the modal background
        }
    </script>
</body>
</html>

"""


def generate_sample_logs():
    logs = []
    for _ in range(2000):  # Generate 20 sample logs
        log = f"Log entry {random.randint(1, 100)}"
        logs.append(log)
    return logs


def get_images_and_metadata():
    image_json_data = []
    for root, dirs, files in os.walk(IMAGE_FOLDER):
        for file in files:
            if file.endswith(".jpg"):
                image_path = os.path.relpath(os.path.join(root, file), IMAGE_FOLDER)
                json_path = os.path.splitext(image_path)[0] + ".json"
                if os.path.exists(os.path.join(IMAGE_FOLDER, json_path)):
                    try:
                        with open(os.path.join(IMAGE_FOLDER, json_path), 'r') as f:
                            json_data = json.load(f)
                        image_json_data.append((image_path, json_data))
                    except Exception as e:
                        print(f"Error loading JSON file: {e}")
    return image_json_data


    
@app.route('/')
def index():
    image_json_pairs = get_images_and_metadata()
    print(image_json_pairs)
    sorted_pairs = sorted(image_json_pairs, key=lambda x: x[1]["Create Seconds Epoch"], reverse=True)
    logs = generate_sample_logs()
    return render_template_string(template, image_json_pairs=sorted_pairs, logs=logs)

@app.route('/waiting')
def waiting():
    image_json_pairs = get_images_and_metadata()
    waiting_pairs = [(image, json_file) for image, json_file in image_json_pairs if "Drone Copy" not in json_file]
    waiting_image_ids = [image for image, _ in waiting_pairs]
    waiting_image_ids = [image.split('.')[0] for image in waiting_image_ids]
    return waiting_image_ids

@app.route('/images/<path:image>')
def serve_image(image):
    return send_from_directory(IMAGE_FOLDER, image)

@app.route('/metadata/<path:json_file>')
def serve_metadata(json_file):
    return send_from_directory(IMAGE_FOLDER, json_file)


if __name__ == '__main__':
  parser = argparse.ArgumentParser(description='Run the wildlife web frontend')
  parser.add_argument('--folder', type=str, default='/home/emli/embedded-linux/wildlife/photos', help='Path to the image folder')
  parser.add_argument('--host', type=str, default='0.0.0.0', help='Host address to bind the application')
  parser.add_argument('--port', type=int, default=8099, help='Port number to listen on')
  parser.add_argument('--debug', action='store_true', default=True, help='Enable debug mode')
  args = parser.parse_args()
 
  IMAGE_FOLDER = args.folder
  app.run(host=args.host, port=args.port, debug=args.debug)
