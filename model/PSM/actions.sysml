package PSM_Actions {

    private import CIM::Actions::*;
    private import ScalarValues::*;
    private import CIM::Datatype::*;
    private import PSM::Interfaces::*;
    private import PSM::PhysicalArchitecture::*;
    private import PSM::ParserData::*;

    doc /* PSM action definitions carrying TypeScript implementations.
       CIM-mapped actions specialize their CIM counterpart via :>.
       PSM-only helper actions (no CIM counterpart) stand alone. */

    action def <ParseMllpFrame> 'Parse MLLP Frame' :> ReceiveMLLPFrame {
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
  return {
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
  return buf;
        */
    }

    action def <BuildAck> 'Build ACK' {
        out buffer : Buffer;
        doc /* Build a minimal HL7 ACK message (MSH + MSA) and wrap in MLLP framing. */

        rep functionBody language "TypeScript"
        /*
  const ack =
    'MSH|^~\\&|HL7Adapter|||2025||ACK^O01^ACK|ack1|P|2.5\rMSA|AA|ack1\r';
  return buildMllpMessage(ack);
        */
    }

    action def <BuildNak> 'Build NAK' {
        out buffer : Buffer;
        doc /* Build a minimal HL7 NAK message and wrap in MLLP framing. */

        rep functionBody language "TypeScript"
        /*
  const nak =
    'MSH|^~\\&|HL7Adapter|||2025||ACK^O01^ACK|nak1|P|2.5\rMSA|AE|nak1|Frame error\r';
  return buildMllpMessage(nak);
        */
    }

    /* =======================================================================
     * Parser: HL7 message parsing (MSH/PID extraction, validation)
     * ======================================================================= */

    action def <ParseHL7Message> 'Parse HL7 Message' {
        in rawMessage : String;
        in strictValidation : Integer;
        in segmentWhitelist : String;
        out result : String;
        doc /* Pure parse: extract MSH and PID, validate required segments/fields. Returns JSON string of ParseResult (success + data or error). */

        rep functionBody language "TypeScript"
        /*
  const segments = rawMessage.split(/[\r\n]+/).filter((s) => s.length > 0);
  if (segments.length === 0) {
    return JSON.stringify({ success: false as const, error: { message: 'Empty message', segment: undefined } });
  }
  const mshSeg = segments[0];
  if (!mshSeg.startsWith('MSH')) {
    return JSON.stringify({ success: false as const, error: { message: 'Missing or invalid MSH segment', segment: mshSeg } });
  }
  const mshFields = mshSeg.split('|');
  const fieldDelim = mshFields[1]?.[0] ?? '|';
  const get = (arr: string[], i: number) => arr[i] ?? '';
    const msh: MSHFields = {
      fieldDelimiter: fieldDelim,
      sendingApplication: get(mshFields, 2),
      sendingFacility: get(mshFields, 3),
      receivingApplication: get(mshFields, 4),
      receivingFacility: get(mshFields, 5),
      messageType: get(mshFields, 8),
      messageControlId: get(mshFields, 9),
      processingId: get(mshFields, 10),
      versionId: get(mshFields, 11),
    };
  if (strictValidation && !msh.messageType) {
    return JSON.stringify({ success: false as const, error: { message: 'MSH-9 message type required', segment: 'MSH' } });
  }
  const segMap: Record<string, string[]> = {};
  for (const seg of segments) {
    const id = seg.slice(0, 3);
    if (!segMap[id]) segMap[id] = [];
    segMap[id].push(seg);
  }
  let pid: PIDFields | undefined;
    const pidSegs = segMap['PID'];
    if (pidSegs && pidSegs[0]) {
      const p = pidSegs[0].split('|');
      const g = (i: number) => p[i] ?? '';
      pid = {
        patientIdList: g(3),
        patientName: g(5),
        dateOfBirth: g(7),
        sex: g(8),
        patientAddress: g(11),
      };
    }
  const data: ParsedHL7 = { msh, pid, segments: segMap };
  return JSON.stringify({ success: true as const, data });
        */
    }

    action def <HandleIncomingHL7> 'Handle Incoming HL7' {
        in :> self : Parser;
        in rawMessage : String;
        doc /* Parse raw message, dispatch HL7HandlerCompleteSignal or HL7HandlerFailedSignal and emit parseComplete/parseFailed. */

        rep textualRepresentation language "TypeScript"
        /*
  const jsonResult = parseMessage(
    rawMessage,
    this._config.strictValidation,
    this._config.segmentWhitelist,
  );
  const result = JSON.parse(jsonResult) as ParseResult;
  if (result.success) {
    this._dispatch('HL7HandlerCompleteSignal');
    this.emit('parseComplete', result.data);
  } else {
    this._dispatch('HL7HandlerFailedSignal');
    this.emit('parseFailed', result.error);
  }
        */
    }

    /* =======================================================================
     * Transformer: parsed HL7 to JSON (field mapping, schema validation)
     * ======================================================================= */

    action def <TransformToJSON> 'Transform To JSON' {
        in parsed : ParsedHL7;
        in jsonPrettyPrint : Integer;
        in schemaValidateOutput : Integer;
        out result : String;
        doc /* Pure transform: map parsed HL7 to output JSON string. Optional schema check. */

        rep functionBody language "TypeScript"
        /*
  const out: TransformOutput = {};
  if (parsed.msh) {
    out.messageType = parsed.msh.messageType;
    out.messageControlId = parsed.msh.messageControlId;
  }
  if (parsed.pid) {
    out.patientId = parsed.pid.patientIdList;
    out.patientName = parsed.pid.patientName;
    out.dateOfBirth = parsed.pid.dateOfBirth;
  }
  if (schemaValidateOutput && !out.messageType && !out.messageControlId) {
    throw new Error('Schema validation failed: messageType or messageControlId required');
  }
  return jsonPrettyPrint ? JSON.stringify(out, null, 2) : JSON.stringify(out);
        */
    }

    action def <HandleTransformRequest> 'Handle Transform Request' {
        in :> self : Transformer;
        in parsed : ParsedHL7;
        doc /* Transform parsed message, dispatch HL7TransformerCompleteSignal or HL7TransformerFailedSignal and emit transformComplete. */

        rep textualRepresentation language "TypeScript"
        /*
  try {
    const jsonStr = transformPayload(
      parsed,
      this._config.jsonPrettyPrint,
      this._config.schemaValidateOutput,
    );
    this._dispatch('HL7TransformerCompleteSignal');
    this.emit('transformComplete', jsonStr);
  } catch (err) {
    this._dispatch('HL7TransformerFailedSignal');
    this.emit('transformFailed', err instanceof Error ? err.message : String(err));
  }
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
          buffer.indexOf(MLLP_START) >= 0
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
        if (!result.done) break;
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

    /* =======================================================================
     * Initialization actions: bindings -> part attributes (construction/bootstrap)
     * ======================================================================= */

    action def <InitializeMLLPReceiver> 'Initialize MLLP Receiver' {
        in 'binding' : MLLPIngressBinding;
        in runtimeConfig : RuntimeConfigBinding;
        in :> self : MLLPReceiver;
        doc /* Sets this part's attributes from binding and runtimeConfig for use at construction/bootstrap. Maps binding.bindHost -> self.bindHost, binding.bindPort -> self.bindPort, binding.maxPayloadSizeBytes -> self.maxPayloadSize, runtimeConfig.connectionIdleTimeoutMs -> self.connectionIdleTimeoutMs (with fallbacks from runtimeConfig where binding omits). */
    }

    action def <InitializeParser> 'Initialize Parser' {
        in runtimeConfig : RuntimeConfigBinding;
        in :> self : Parser;
        doc /* Sets this part's attributes from runtimeConfig (or defaults) for use at construction/bootstrap. Maps encodingFallback, strictValidation, segmentWhitelist from runtimeConfig where present. */
    }

    action def <InitializeTransformer> 'Initialize Transformer' {
        in runtimeConfig : RuntimeConfigBinding;
        in :> self : Transformer;
        doc /* Sets this part's attributes from runtimeConfig for use at construction/bootstrap. Maps mappingConfigPath, jsonPrettyPrint, schemaValidateOutput from runtimeConfig. */
    }

    action def <InitializeHTTPForwarder> 'Initialize HTTP Forwarder' {
        in 'binding' : HTTPEgressBinding;
        in runtimeConfig : RuntimeConfigBinding;
        in :> self : HTTPForwarder;
        doc /* Sets this part's attributes from binding and runtimeConfig for use at construction/bootstrap. Maps baseUrl (from binding.baseUrlPattern or runtimeConfig.baseUrl), requestTimeoutMs, maxRetries, retryBackoffMs, tlsMinVersion, tlsRejectUnauthorized from binding/runtimeConfig. */
    }

    action def <InitializeErrorHandler> 'Initialize Error Handler' {
        in runtimeConfig : RuntimeConfigBinding;
        in :> self : ErrorHandler;
        doc /* Sets this part's attributes from runtimeConfig for use at construction/bootstrap. Maps logLevel, metricsPrefix, deadLetterPath, classificationTaxonomy from runtimeConfig. */
    }

    action def <BootstrapAdapter> 'Bootstrap Adapter' {
        in mllpBinding : MLLPIngressBinding;
        in httpBinding : HTTPEgressBinding;
        in runtimeConfig : RuntimeConfigBinding;
        in :> self : HL7AdapterService;
        doc /* Supply bindings once and initialize the whole adapter. Composes: invoke InitializeMLLPReceiver on self.mllpReceiver with mllpBinding and runtimeConfig; InitializeParser on self.parser with runtimeConfig; InitializeTransformer on self.transformer with runtimeConfig; InitializeHTTPForwarder on self.httpForwarder with httpBinding and runtimeConfig; InitializeErrorHandler on self.errorHandler with runtimeConfig. */
    }
}
