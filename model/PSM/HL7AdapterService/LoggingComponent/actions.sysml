package PSM_Logging_Actions {

    alias Logging for PSM_LoggingComponent::Logging;
    alias Logger for PSM_Logging_Structure::Logger;
    alias EventEmitterRef for PSM_Logging_Structure::EventEmitterRef;

    private import ScalarValues::*;

    doc /* Logging component actions: initialize root logger, getLogger returns a pino child, attachTo subscribes to transition events. */

    action def <InitializeLogging> 'Initialize Logging' {
        in :> self : Logging;
        doc /* Create root pino logger from config (logLevel, format); set this._root. */
        rep functionBody language "TypeScript"
        /*
  const level = ((this._config?.logLevel as string) ?? 'info').trim() || 'info';
  const opts: pino.LoggerOptions = { level };
  if ((this._config as { format?: string })?.format === 'text') {
    opts.transport = { target: 'pino/file', options: { destination: 1 } };
  }
  this._root = pino(opts);
        */
    }

    action def <GetLogger> 'Get Logger' {
        in :> self : Logging;
        in componentName : String;
        out result : Logger;
        doc /* Return a pino child logger with component field set to componentName. */
        rep functionBody language "TypeScript"
        /*
  result = this._root.child({ component: componentName });
        */
    }

    action def <AttachTo> 'Attach To' {
        in :> self : Logging;
        in emitter : EventEmitterRef;
        in componentName : String;
        doc /* Subscribe to emitter's 'transition' event and log via getLogger(componentName). */
        rep functionBody language "TypeScript"
        /*
  emitter.on('transition', (ev: { from: string; to: string; signal: string }) => {
    this.getLogger(componentName).info(ev, 'state transition');
  });
        */
    }
}
