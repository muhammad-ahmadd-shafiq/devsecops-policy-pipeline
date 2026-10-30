from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/")
def home():
    return jsonify(
        {
            "Application" : "Devsecops-Policy-Pipeline",
            "message":"Policy-as-Code Delivery Pipeline",
            "status":"running"
        }
    )

@app.get("/health")
def health():
    return jsonify({"status":"running"}), 200

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000)

    