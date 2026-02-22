package PSM_MLLPReceiver_Actions {

    alias MLLPReceiver for PSM_MllpReceiverComponent::MLLPReceiver;
    alias MLLPIngressBinding for PSM_MLLPReceiverComponent_Interface::MLLPIngressBinding;
    alias ParseMllpResult for PSM_MLLPReceiver_Structure::ParseMllpResult;
    alias HL7AdapterServiceStatus for PSM_HL7AdapterService_Structure::HL7AdapterServiceStatus;

    private import ScalarValues::*;
    private import CIM::Datatype::*;

    doc /* MLLP Receiver action definitions (parse frame, build message, start/stop, initialize). */

    action def <ParseMllpFrame> 'Parse MLLP Frame' :> CIM::Actions::ReceiveMLLPFrame {
        in buffer : Buffer;
        in maxPayloadSize : Integer;
        out result : ParseMllpResult;
        doc /* Parse one MLLP frame from a buffer. Returns payload, error status, and consumed byte count. Testable without starting the TCP server. */

        rep functionBody language "TypeScript"
        /*
  const startIdx = buffer.indexOf(MLLP_START_BYTE);
  if (startIdx < 0) {
    return {
      payload: undefined,
      success: false,
      error: 'no start block found',
      consumed: buffer.length,
    };
  }
  const payloadStart = startIdx + 1;
  const endIdx = buffer.indexOf(MLLP_END_BYTE_FIRST, payloadStart);
  if (endIdx < 0) {
    return { success: false, consumed: startIdx };
  }
  if (buffer[endIdx + 1] !== MLLP_END_BYTE_SECOND) {
    return {
      payload: undefined,
      success: false,
      error: 'invalid end block (expected 0x1C 0x0D)',
      consumed: endIdx + 2,
    };
  }
  const payloadLength = endIdx - payloadStart;
  if (payloadLength > maxPayloadSize) {
    return {
      payload: undefined,
      success: false,
      error: `payload exceeds max size ${maxPayloadSize}`,
      consumed: endIdx + 2,
    };
  }
  const payload = buffer.subarray(payloadStart, endIdx);
  result = {
    payload: Buffer.from(payload),
    success: true,
    error: undefined,
    consumed: endIdx + 2,
  };
        */
    }

    action def <BuildMllpMessage> 'Build MLLP Message' {
        in content : String;
        out buffer : Buffer;
        doc /* Wrap a content string in MLLP framing bytes (0x0B start, 0x1C 0x0D end). */

        rep functionBody language "TypeScript"
        /*
  const buf = Buffer.alloc(1 + Buffer.byteLength(content, 'utf8') + 2);
  let off = 0;
  buf[off++] = MLLP_START_BYTE;
  off += buf.write(content, off, 'utf8');
  buf[off++] = MLLP_END_BYTE_FIRST;
  buf[off++] = MLLP_END_BYTE_SECOND;
  buffer = buf;
        */
    }

    action def <BuildAck> 'Build ACK' {
        out buffer : Buffer;
        doc /* Build a minimal HL7 ACK message (MSH + MSA) and wrap in MLLP framing. */

        rep functionBody language "TypeScript"
        /*
  const ack =
    'MSH|^~\\&|HL7Adapter|||2025||ACK^O01^ACK|ack1|P|2.5\rMSA|AA|ack1\r';
  buffer = buildMllpMessage(ack);
        */
    }

    action def <BuildNak> 'Build NAK' {
        out buffer : Buffer;
        doc /* Build a minimal HL7 NAK message and wrap in MLLP framing. */

        rep functionBody language "TypeScript"
        /*
  const nak =
    'MSH|^~\\&|HL7Adapter|||2025||ACK^O01^ACK|nak1|P|2.5\rMSA|AE|nak1|Frame error\r';
  buffer = buildMllpMessage(nak);
        */
    }

    action def <StartReceiver> 'Start Receiver' {
        in :> self;
        doc /* Start the MLLP TCP listener and begin accepting connections. */

        rep functionBody language "TypeScript"
        /*
start(): void {
  if (this._server) {
    logger.warn('MLLP server already listening');
    return;
  }
  this._server = net.createServer((socket) => {
    let buffer = Buffer.alloc(0);
    let idleTimer: ReturnType<typeof setTimeout> | null = null;

    const resetIdle = () => {
      if (idleTimer) clearTimeout(idleTimer);
      idleTimer = setTimeout(() => {
        logger.info({ remote: socket.remoteAddress }, 'connection idle timeout');
        socket.destroy();
      }, this._config.connectionIdleTimeoutMs);
    };

    socket.on('data', (chunk: Buffer) => {
      resetIdle();
      buffer = Buffer.concat([buffer, chunk]);
      for (;;) {
        const s = this._state;
        if (
          (s === MllpReceiverState.LISTENING || s === MllpReceiverState.FRAME_COMPLETE) &&
          buffer.length > 0 &&
          buffer.indexOf(MLLP_START_BYTE) >= 0
        ) {
          this._dispatch('MLLPFrameReceivedSignal');
        }
        const result = parseMllpFrame(buffer, this._config.maxPayloadSize);
        if (result.error) {
          this._dispatch('MLLPFrameErrorSignal');
          try {
            socket.write(buildNak());
          } catch {
            // ignore write errors
          }
          socket.destroy();
          return;
        }
        if (!result.success && !result.error) break;
        if (result.payload) {
          this._dispatch('MLLPFrameCompleteSignal');
          this.emit('frameComplete', result.payload);
          try {
            socket.write(buildAck());
          } catch {
            // ignore
          }
        }
        buffer = buffer.subarray(result.consumed);
      }
    });

    socket.on('close', () => {
      if (idleTimer) clearTimeout(idleTimer);
    });

    socket.on('error', (err) => {
      logger.warn({ err }, 'socket error');
      if (idleTimer) clearTimeout(idleTimer);
    });

    resetIdle();
  });

  this._server.listen(this._config.bindPort, this._config.bindHost, () => {
    logger.info(
      { host: this._config.bindHost, port: this._config.bindPort },
      'MLLP listener started',
    );
    this._dispatch('ListenerStartSignal');
  });

  this._server.on('error', (err) => {
    logger.error({ err }, 'MLLP server error');
    this._dispatch('MLLPFrameErrorSignal');
  });
}
        */
    }

    action def <StopReceiver> 'Stop Receiver' {
        in :> self;
        doc /* Stop the MLLP TCP listener gracefully. */

        rep functionBody language "TypeScript"
        /*
stop(): void {
  if (!this._server) return;
  const s = this._server;
  this._server = null;
  s.close(() => {
    logger.info('MLLP listener stopped');
    this._dispatch('ListenerStopSignal');
  });
}
        */
    }

    action def <InitializeMLLPReceiver> 'Initialize MLLP Receiver' {
        in 'binding' : MLLPIngressBinding;
        in :> self : MLLPReceiver;
        doc /* Sets this part's attributes from binding and runtimeConfig for use at construction/bootstrap. Maps binding.bindHost -> self.bindHost, binding.bindPort -> self.bindPort, binding.maxPayloadSizeBytes -> self.maxPayloadSize, runtimeConfig.connectionIdleTimeoutMs -> self.connectionIdleTimeoutMs (with fallbacks from runtimeConfig where binding omits). */
    }

    action def <GetMLLPReceiverStatus> 'Get MLLP Receiver Status' {
        in :> self : MLLPReceiver;
        out result : HL7AdapterServiceStatus;
        doc /* Return current component state for health/status endpoints. */
        rep functionBody language "TypeScript"
        /*
  result = { status: this.state };
        */
    }
}
