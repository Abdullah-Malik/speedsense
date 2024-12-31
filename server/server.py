from flask import Flask, request, jsonify, render_template
from sqlalchemy import create_engine, Column, Integer, Float, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from scipy.signal import find_peaks

app = Flask(__name__)

# Configure SQLite database
DATABASE_URL = 'sqlite:///speedsense.db'
engine = create_engine(DATABASE_URL)
Base = declarative_base()

# Database Models
class AccelerometerData(Base):
    __tablename__ = 'accelerometer_data'
    id = Column(Integer, primary_key=True)
    unique_timestamp = Column(Float, nullable=False, unique=True)
    timestamp = Column(DateTime, nullable=False)
    x = Column(Float, nullable=True)
    y = Column(Float, nullable=True)
    z = Column(Float, nullable=True)
    magnitude = Column(Float, nullable=True)

class GyroscopeData(Base):
    __tablename__ = 'gyroscope_data'
    id = Column(Integer, primary_key=True)
    unique_timestamp = Column(Float, nullable=False, unique=True)
    timestamp = Column(DateTime, nullable=False)
    x = Column(Float, nullable=True)
    y = Column(Float, nullable=True)
    z = Column(Float, nullable=True)
    magnitude = Column(Float, nullable=True)

# Create database tables
Base.metadata.create_all(engine)

# Set up the database session
Session = sessionmaker(bind=engine)
session = Session()

# Routes
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/data', methods=['POST'])
def process_sensor_data():
    data = request.json
    if not data or 'sensor_type' not in data or 'data' not in data:
        return jsonify({"error": "Invalid payload"}), 400

    sensor_type = data['sensor_type']

    # Sanitize and parse the base timestamp
    try:
        base_timestamp_str = data['timestamp'].replace("Z", "+00:00").replace(" ", "")
        base_timestamp = datetime.fromisoformat(base_timestamp_str)
    except ValueError:
        return jsonify({"error": f"Invalid timestamp format: {data['timestamp']}"}), 400

    # Initialize unique timestamp with millisecond offset
    unique_base_timestamp = base_timestamp.timestamp() * 1000  # Convert to milliseconds
    offset_ms = 0  # Start with 0 milliseconds offset

    # Process each record in the "data" array
    for record in data['data']:
        try:
            record_timestamp_str = record['timestamp'].replace("Z", "+00:00").replace(" ", "")
            record_timestamp = datetime.fromisoformat(record_timestamp_str)
        except ValueError:
            return jsonify({"error": f"Invalid timestamp format in record: {record['timestamp']}"}), 400

        # Generate a unique timestamp using millisecond offset
        unique_timestamp = unique_base_timestamp + offset_ms
        offset_ms += 1  # Increase the offset by 1 millisecond for each record

        # Add data to the respective table
        if sensor_type == "accelerometer":
            accelerometer_entry = AccelerometerData(
                unique_timestamp=unique_timestamp,
                timestamp=record_timestamp,
                x=record.get('x') * 9.81,
                y=record.get('y') * 9.81,
                z=record.get('z') * 9.81,
                magnitude=record.get('magnitude') * 9.81,
            )
            session.add(accelerometer_entry)

        elif sensor_type == "gyroscope":
            gyroscope_entry = GyroscopeData(
                unique_timestamp=unique_timestamp,
                timestamp=record_timestamp,
                x=record.get('x'),
                y=record.get('y'),
                z=record.get('z'),
                magnitude=record.get('magnitude')
            )
            session.add(gyroscope_entry)
        else:
            return jsonify({"error": f"Unknown sensor type: {sensor_type}"}), 400

    # Commit all changes to the database
    session.commit()

    return jsonify({"status": "success", "processed_count": len(data['data'])}), 200

@app.route('/get-data', methods=['GET'])
def get_data():
    try:
        # Fetch all rows from GyroscopeData table
        gyroscope_data = session.query(GyroscopeData).all()
        gyroscope_data_list = [
            {
                "id": record.id,
                "unique_timestamp": record.unique_timestamp,
                "timestamp": record.timestamp.isoformat(),
                "x": record.x,
                "y": record.y,
                "z": record.z,
                "magnitude": record.magnitude
            }
            for record in gyroscope_data
        ]

        # Fetch all rows from AccelerometerData table
        accelerometer_data = session.query(AccelerometerData).all()
        accelerometer_data_list = [
            {
                "id": record.id,
                "unique_timestamp": record.unique_timestamp,
                "timestamp": record.timestamp.isoformat(),
                "x": record.x,
                "y": record.y,
                "z": record.z,
                "magnitude": record.magnitude
            }
            for record in accelerometer_data
        ]

        # Combine both tables into a single response
        response = {
            "gyroscope_data": gyroscope_data_list,
            "accelerometer_data": accelerometer_data_list
        }

        return jsonify(response), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/get-data-between', methods=['GET'])
def get_data_between():
    try:
        start = request.args.get('start')
        end = request.args.get('end')
        if not start or not end:
            return jsonify({"error": "Start and end timestamps are required"}), 400

        # Parse the timestamps
        start_timestamp = datetime.fromisoformat(start.replace("Z", "+00:00"))
        end_timestamp = datetime.fromisoformat(end.replace("Z", "+00:00"))

        # Query the database for data between timestamps
        accelerometer_data = session.query(AccelerometerData).filter(
            AccelerometerData.timestamp >= start_timestamp,
            AccelerometerData.timestamp <= end_timestamp
        ).all()
        gyroscope_data = session.query(GyroscopeData).filter(
            GyroscopeData.timestamp >= start_timestamp,
            GyroscopeData.timestamp <= end_timestamp
        ).all()

        accelerometer_data_list = [
            {"id": record.id, "x": record.x, "y": record.y, "z": record.z, "magnitude": record.magnitude}
            for record in accelerometer_data
        ]
        gyroscope_data_list = [
            {"id": record.id, "x": record.x, "y": record.y, "z": record.z, "magnitude": record.magnitude}
            for record in gyroscope_data
        ]

        # Extract magnitudes, IDs, and timestamps
        accelerometer_magnitudes = [record.magnitude for record in accelerometer_data]
        accelerometer_ids = [record.id for record in accelerometer_data]

        gyroscope_magnitudes = [record.magnitude for record in gyroscope_data]
        gyroscope_ids = [record.id for record in gyroscope_data]

        # Detect peaks in accelerometer magnitudes
        peaks, properties = find_peaks(accelerometer_magnitudes, height=10)

        speed_data = [
            {"id": record.id, "speed": 0}
            for record in accelerometer_data
        ]


        for peak in peaks:
            speed = 0
            i = peak
            while accelerometer_magnitudes[i] > 0.5 and i > 0:
                speed += accelerometer_magnitudes[i] * (0.01)
                i -= 1
            speed_data[peak]["speed"] = speed

        return jsonify({
            "accelerometer_data": accelerometer_data_list,
            "gyroscope_data": gyroscope_data_list,
            "speed_data": speed_data
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
