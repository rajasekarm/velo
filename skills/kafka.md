---
name: kafka
description: Kafka event streaming with KafkaJS, consumers, producers, schema management. Manual offset commits, dead letter topics, idempotent processing, Avro schemas.
---
# Kafka

**Scope:** Event streaming with KafkaJS, consumers, producers, schema management.

## Rules
- Explicit `groupId` on every consumer
- `eachMessage` with try/catch — failed messages go to `<topic>.DLT`
- `autoCommit: false` — commit manually after processing
- Schema Registry + Avro for production; JSON only for prototyping
- Graceful shutdown on SIGTERM/SIGINT

## Consumer Patterns
- Idempotent processing — design for at-least-once delivery
- Dead letter topic (DLT) for poison messages
- Backpressure handling — don't let consumer lag grow unbounded
- Offset management — commit after successful processing only

## Producer Patterns
- Acks: `all` for critical data, `1` for best-effort
- Key-based partitioning for ordering guarantees
- Compression (snappy/lz4) for throughput

## Monitoring
- Consumer lag per partition
- DLT message count
- Producer error rate
