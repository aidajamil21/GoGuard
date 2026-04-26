import json
import random
import uuid
from datetime import datetime


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET",
            "Content-Type": "application/json",
        },
        "body": json.dumps(body),
    }


def _parse_body(event):
    try:
        return json.loads(event.get("body") or "{}")
    except Exception:
        return {}


def generate_graph_features(phone):
    last_digit = int(phone[-1]) if phone and phone[-1].isdigit() else 5
    return {
        "degree_centrality": round(random.uniform(0.1, 0.9), 3),
        "betweenness_centrality": round(random.uniform(0.0, 0.5), 3),
        "clustering_coefficient": round(random.uniform(0.2, 0.8), 3),
        "num_reported_connections": random.randint(0, 5),
        "avg_neighbor_risk": round(random.uniform(0.1, 0.7), 3),
        "transaction_frequency": random.randint(1, 50),
        "is_isolated_node": last_digit < 2,
    }


def generate_shap_values():
    return {
        "amount": round(random.uniform(-0.15, 0.25), 4),
        "hour_of_day": round(random.uniform(-0.1, 0.15), 4),
        "is_new_recipient": round(random.uniform(-0.05, 0.3), 4),
        "velocity": round(random.uniform(-0.1, 0.2), 4),
        "day_of_week": round(random.uniform(-0.05, 0.1), 4),
        "user_history_score": round(random.uniform(-0.2, 0.1), 4),
    }


def calculate_gnn_score(phone):
    if not phone:
        return 0.5
    last_digit = int(phone[-1]) if phone[-1].isdigit() else 5
    if last_digit <= 2:
        return round(random.uniform(0.15, 0.35), 2)
    elif last_digit <= 6:
        return round(random.uniform(0.40, 0.65), 2)
    else:
        return round(random.uniform(0.70, 0.90), 2)


def calculate_xgb_score(amount, hour, velocity, is_new):
    score = 0.3
    if amount > 500:
        score += 0.2
    elif amount > 200:
        score += 0.1
    if hour < 6 or hour > 22:
        score += 0.15
    if is_new:
        score += 0.1
    if velocity > 5:
        score += 0.15
    score += random.uniform(-0.05, 0.05)
    return round(max(0.0, min(1.0, score)), 2)


def handler(event, context):
    path = event.get("path", "/")
    method = event.get("httpMethod", "GET")

    if method == "OPTIONS":
        return _response(200, {})

    if method == "GET" and path in ("/", "/api"):
        return _response(200, {
            "service": "GOguard Backend",
            "status": "running",
            "version": "1.0.0",
            "timestamp": datetime.now().isoformat(),
        })

    if method == "GET" and path in ("/health", "/api/health"):
        return _response(200, {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "endpoints": {
                "recipient_check": "/api/recipients/check",
                "risk_score": "/api/ml/risk-score",
                "transfer_execute": "/api/transfers/execute",
            },
        })

    if method == "POST" and path in ("/recipients/check", "/api/recipients/check"):
        body = _parse_body(event)
        phone = body.get("phone", "")
        return _response(200, {
            "scam_check_id": f"chk_{uuid.uuid4().hex[:12]}",
            "gnn_risk_score": calculate_gnn_score(phone),
            "graph_features": generate_graph_features(phone),
            "message": "Recipient check completed",
        })

    if method == "POST" and path in ("/ml/risk-score", "/api/ml/risk-score"):
        body = _parse_body(event)
        score = calculate_xgb_score(
            body.get("amount", 0),
            body.get("hour_of_day", 12),
            body.get("velocity", 0),
            body.get("is_new_recipient", False),
        )
        return _response(200, {
            "xgb_risk_score": score,
            "shap_values": generate_shap_values(),
            "message": "Risk score calculated",
        })

    if method == "POST" and path in ("/transfers/execute", "/api/transfers/execute"):
        body = _parse_body(event)
        ml_score = body.get("ml_score", 0)
        amount = body.get("amount", 0)

        if ml_score >= 0.85:
            return _response(403, {"detail": "Transfer blocked due to high scam risk"})
        if amount > 1000:
            return _response(402, {"detail": "Insufficient funds"})
        if random.random() < 0.05:
            return _response(504, {"detail": "Request timeout"})

        return _response(200, {
            "txn_id": f"txn_{uuid.uuid4().hex[:16]}",
            "timestamp": datetime.now().isoformat(),
            "status": "completed",
            "message": "Transfer completed successfully",
        })

    return _response(404, {"detail": "Not found"})
