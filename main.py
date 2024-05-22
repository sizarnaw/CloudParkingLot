from flask import Flask, request, jsonify
from datetime import datetime, timedelta
import random

app = Flask(__name__)

#In-memory database for storing parking entries
parking_entries = []

#Endpoint for recording entry
@app.route('/entry', methods=['POST'])
def recordentry():
    plate = request.args.get('plate')
    parking_lot = request.args.get('parkingLot')
    entry_time = datetime.now()
    ticket_id = random.randint(1000, 9999)  # Generating a random ticket id
    entry = {'ticketId': ticket_id, 'plate': plate, 'parkingLot': parking_lot, 'entryTime': entry_time}
    parking_entries.append(entry)
    return jsonify({'ticketId': ticket_id})

#Endpoint for recording exit and calculating charge
@app.route('/exit', methods=['POST'])
def record_exit():
    ticket_id = request.args.get('ticketId')
    exit_time = datetime.now()
    entry = next((entry for entry in parking_entries if entry['ticketId'] == int(ticket_id)), None)
    if not entry:
        return jsonify({'error': 'Ticket not found'}), 404

    parked_time = exit_time - entry['entryTime']
    parked_time_in_hours = parked_time.total_seconds() / 3600
    charge = round(parked_time_in_hours * 10, 2)  # Charge is $10 per hour

    return jsonify({
        'plate': entry['plate'],
        'parkingLot': entry['parkingLot'],
        'parkedTime': str(parked_time),
        'charge': f'${charge}'
    })

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port='8000')