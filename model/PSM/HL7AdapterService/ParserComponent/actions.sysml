package PSM_Parser_Actions {

    alias Parser for PSM_ParserComponent::Parser;
    alias Structure for PSM_Parser_Structure;

    private import ScalarValues::*;
    private import PSM_HL7AdapterService_Structure::*;
    doc /* Parser action definitions (parse message, handle incoming, initialize). */

    action def <ParseHL7Message> 'Parse HL7 Message' {
        in rawMessage : String;
        in strictValidation : Integer;
        in segmentWhitelist : String;
        out result : String;
        doc /* Pure parse: extract MSH and PID, validate required segments/fields. Returns JSON string of ParseResult (success + data or error). */

        rep functionBody language "TypeScript"
        /*
  const lines = rawMessage.split(/\r\n?|\n/);
  const segments: string[] = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed.length) continue;
    const parts = trimmed.split(/\s+(?=[A-Z][A-Z0-9]{1,2}\|)/);
    for (const part of parts) {
      const s = part.trim();
      if (s.length > 0) segments.push(s);
    }
  }
  if (segments.length === 0) {
    return JSON.stringify({ success: false as const, error: { message: 'Empty message', segment: undefined } });
  }
  const mshSeg = segments[0];
  if (!mshSeg.startsWith('MSH')) {
    return JSON.stringify({ success: false as const, error: { message: 'Missing or invalid MSH segment', segment: mshSeg } });
  }
  const mshFields = mshSeg.split('|');
  const fieldDelim = mshFields[1]?.[0] ?? '|';
  const get = (arr: string[], i: number) => (arr[i] ?? '').trim();
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
    const g = (i: number) => (p[i] ?? '').trim();
    pid = {
      patientIdList: g(3) || undefined,
      patientName: g(5) || undefined,
      dateOfBirth: g(7) || undefined,
      sex: g(8) || undefined,
      patientAddress: g(11) || undefined,
    };
  }
  const data: ParsedHL7 = { msh, pid, segments: segMap };
  result = JSON.stringify({ success: true as const, data });
        */
    }

    action def <HandleIncomingHL7> 'Handle Incoming HL7' {
        in :> self : Parser;
        in rawMessage : String;
        doc /* Parse raw message, dispatch HL7HandlerCompleteSignal or HL7HandlerFailedSignal and emit parseComplete/parseFailed. */

        rep textualRepresentation language "TypeScript"
        /*
  this._logger.info({ length: rawMessage.length }, 'Parser: parsing message');
  const jsonResult = parseMessage(
    rawMessage,
    this._config.strictValidation,
    this._config.segmentWhitelist,
  );
  const result = JSON.parse(jsonResult) as ParseResult;
  if (result.success) {
    this._logger.info('Parser: parse complete');
    this._dispatch('HL7HandlerCompleteSignal');
    this.emit('parseComplete', result.data);
  } else {
    this._logger.warn({ error: result.error }, 'Parser: parse failed');
    this._dispatch('HL7HandlerFailedSignal');
    this.emit('parseFailed', result.error);
  }
        */
    }

    action def <ExtractMessageControlId> 'Extract Message Control ID' {
        in rawMessage : String;
        in strictValidation : Integer;
        in segmentWhitelist : String;
        out result : String [0..1];
        doc /* Pure function: parse raw message and return MSH-10 (Message Control ID) when present. */
        rep functionBody language "TypeScript"
        /*
  const jsonResult = parseMessage(rawMessage, strictValidation, segmentWhitelist);
  try {
    const parsed = JSON.parse(jsonResult) as ParseResult;
    if (parsed.success && parsed.data.msh.messageControlId) {
      const id = parsed.data.msh.messageControlId.trim();
      result = id.length > 0 ? id : undefined;
    }
  } catch {
    result = undefined;
  }
        */
    }

    action def <GetMessageControlId> 'Get Message Control ID' {
        in rawMessage : String;
        out result : String [0..1];
        in :> self : Parser;
        doc /* Return MSH-10 from raw message using this parser's config (for service to use as message_id). */
        rep functionBody language "TypeScript"
        /*
  result = extractMessageControlId(rawMessage, this._config.strictValidation, this._config.segmentWhitelist);
        */
    }

    action def <InitializeParser> 'Initialize Parser' {
        in :> self : Parser;
        doc /* Sets this part's attributes from runtimeConfig (or defaults) for use at construction/bootstrap. Maps encodingFallback, strictValidation, segmentWhitelist from runtimeConfig where present. */
        rep functionBody language "TypeScript"
        /*
  this._logger.info('Parser initialised');
        */
    }

    action def <GetParserStatus> 'Get Parser Status' {
        in :> self : Parser;
        out result : HL7AdapterServiceStatus;
        doc /* Return current component state for health/status endpoints. */
        rep functionBody language "TypeScript"
        /*
  result = { status: this.state };
        */
    }
}
