import math
from flask import Flask, request, jsonify
from datetime import datetime
import random

app = Flask(__name__)

parking_entries = []


@app.route('/entry', methods=['POST'])
def record_entry():
    plate = request.args.get('plate')
    spot = request.args.get('parkingLot')
    entry_time = datetime.now()
    ticket_id = random.randint(1000, 99999)
    finished = False
    while not finished:
        if ticket_id not in parking_entries['ticketId']:
            entry = {'ticketId': ticket_id, 'plate': plate, 'parkingLot': spot, 'entryTime': entry_time}
            parking_entries.append(entry)
            finished = True
        else:
            ticket_id = random.randint(1000, 99999)

    return jsonify({'ticketId': ticket_id})


@app.route('/exit', methods=['POST'])
def record_exit():
    ticket_id = request.args.get('ticketId')
    exit_time = datetime.now()
    entry = next((entry for entry in parking_entries if entry['ticketId'] == int(ticket_id)), None)
    if not entry:
        return jsonify({'error': 'Ticket not found'}), 404

    parked_time = exit_time - entry['entryTime']
    parked_time_in_minutes = parked_time.total_seconds() / 60
    increments = math.ceil(parked_time_in_minutes / 15)
    charge = round(increments * 2.5, 2)

    return jsonify({
        'plate': entry['plate'],
        'parkingLot': entry['parkingLot'],
        'parkedTime': str(parked_time),
        'charge': f'${charge}'
    })


if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port='8000')
