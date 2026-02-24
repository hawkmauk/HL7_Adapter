/**
 * Dashboard frontend: polls RestAPI for health, metrics, messages, and errors.
 * Config: load config.json for baseUrl and pollIntervalSeconds; or set window.DASHBOARD_CONFIG before load.
 */
(function () {
  const defaultConfig = {
    baseUrl: 'http://localhost:3000',
    pollIntervalSeconds: 5
  };

  let config = { ...defaultConfig };
  let pollTimer = null;
  let lastError = null;
  let lastHealth = null;
  let lastMetrics = null;
  let lastMessages = null;
  let lastErrors = null;

  function getConfig() {
    if (typeof window.DASHBOARD_CONFIG === 'object' && window.DASHBOARD_CONFIG !== null) {
      return { ...defaultConfig, ...window.DASHBOARD_CONFIG };
    }
    return config;
  }

  function loadConfig(cb) {
    fetch('config.json')
      .then(function (r) { return r.ok ? r.json() : Promise.reject(new Error('config.json not found')); })
      .then(function (c) {
        config = { ...defaultConfig, ...c };
        if (cb) cb();
      })
      .catch(function () {
        config = defaultConfig;
        if (cb) cb();
      });
  }

  function get(url) {
    return fetch(url, { method: 'GET', headers: { Accept: 'application/json' } })
      .then(function (r) {
        if (!r.ok) throw new Error(r.status + ' ' + r.statusText);
        return r.json();
      });
  }

  function api(path) {
    const base = getConfig().baseUrl.replace(/\/$/, '');
    return get(base + path);
  }

  function renderHealth(data) {
    lastHealth = data;
    const el = document.getElementById('health');
    if (!el) return;
    const status = data && data.status ? data.status : '—';
    const comp = (data && data.components) ? data.components : {};
    let html = '<p><strong>Status:</strong> <span class="status-' + status + '">' + escapeHtml(status) + '</span></p>';
    html += '<table><thead><tr><th>Component</th><th>Status</th></tr></thead><tbody>';
    const names = ['errorHandler', 'mllpReceiver', 'parser', 'transformer', 'httpForwarder', 'restApi'];
    names.forEach(function (n) {
      const c = comp[n];
      const s = (c && typeof c.status !== 'undefined') ? c.status : '—';
      html += '<tr><td>' + escapeHtml(n) + '</td><td>' + escapeHtml(String(s)) + '</td></tr>';
    });
    html += '</tbody></table>';
    el.innerHTML = html;
  }

  function renderMetrics(data) {
    lastMetrics = data;
    const el = document.getElementById('metrics');
    if (!el) return;
    const eh = (data && data.components && data.components.errorHandler) ? data.components.errorHandler : {};
    const storedTotal = typeof data.errors_stored_total === 'number' ? data.errors_stored_total : 0;
    const fields = [
      'messages_received', 'messages_parsed', 'messages_transformed', 'messages_delivered',
      'errors_total', 'errors_parse_error', 'errors_validation_error', 'errors_connection_error',
      'errors_timeout_error', 'errors_http_client_error', 'errors_http_server_error'
    ];
    let html = '<table><thead><tr><th>Metric</th><th>Value</th></tr></thead><tbody>';
    html += '<tr><td>errors_stored_total</td><td>' + storedTotal + '</td></tr>';
    fields.forEach(function (f) {
      const v = typeof eh[f] === 'number' ? eh[f] : 0;
      html += '<tr><td>' + escapeHtml(f) + '</td><td>' + v + '</td></tr>';
    });
    html += '</tbody></table>';
    el.innerHTML = html;
  }

  function toMessageList(data) {
    if (Array.isArray(data)) return data;
    if (data && typeof data === 'object' && Array.isArray(data.messages)) return data.messages;
    if (data && typeof data === 'object' && Array.isArray(data.data)) return data.data;
    if (data && typeof data === 'object' && Array.isArray(data.result)) return data.result;
    return [];
  }

  function renderMessages(data) {
    lastMessages = data;
    const el = document.getElementById('messages');
    if (!el) return;
    const list = toMessageList(data);
    const sorted = list.slice().sort(function (a, b) {
      const ta = (a && a.received_at) ? new Date(a.received_at).getTime() : 0;
      const tb = (b && b.received_at) ? new Date(b.received_at).getTime() : 0;
      return tb - ta;
    });
    const ten = sorted.slice(0, 10);
    let html = '<table><thead><tr><th>message_id</th><th>status</th><th>received_at</th><th>message_type</th><th>control_id</th><th>Patient</th></tr></thead><tbody>';
    ten.forEach(function (m) {
      var msgId = m.message_id ?? m.messageId ?? '';
      var statusVal = m.status ?? '';
      var recvAt = m.received_at ?? m.receivedAt ?? '';
      var msgType = m.message_type != null ? m.message_type : (m.messageType != null ? m.messageType : '');
      var ctrlId = m.control_id != null ? m.control_id : (m.controlId != null ? m.controlId : '');
      var demo = m.demographics;
      var patientLabel = demo ? [demo.familyName, demo.givenName].filter(Boolean).join(', ') || demo.patientId || '—' : '—';
      html += '<tr class="msg-row" data-message-id="' + escapeHtml(String(msgId)) + '" title="Click to view message detail (metadata, demographics)"><td>' + escapeHtml(String(msgId)) + '</td><td>' + escapeHtml(String(statusVal)) + '</td><td>' + escapeHtml(String(recvAt)) + '</td><td>' + escapeHtml(String(msgType)) + '</td><td>' + escapeHtml(String(ctrlId)) + '</td><td>' + escapeHtml(String(patientLabel)) + '</td></tr>';
    });
    html += '</tbody></table>';
    el.innerHTML = html;
  }

  function showPayloadModal(messageId) {
    var modal = document.getElementById('payload-modal');
    var content = document.getElementById('payload-modal-content');
    var titleEl = document.getElementById('payload-modal-title');
    if (!modal || !content) return;
    modal.classList.add('visible');
    if (titleEl) titleEl.textContent = 'Message detail (adapter API)';
    var base = getConfig().baseUrl.replace(/\/$/, '');
    if (!base) {
      content.textContent = 'Configure baseUrl in config.json to load message detail from the adapter.';
      return;
    }
    content.innerHTML = 'Loading…';
    var url = base + '/messages/' + encodeURIComponent(messageId);
    fetch(url, { method: 'GET', headers: { Accept: 'application/json' } })
      .then(function (r) {
        if (!r.ok) throw new Error(r.status === 404 ? 'Message not found' : r.status + ' ' + r.statusText);
        return r.json();
      })
      .then(function (data) {
        content.innerHTML = formatMessageDetail(data);
      })
      .catch(function (err) {
        content.innerHTML = '<p class="detail-muted">Error: ' + escapeHtml(err && err.message ? err.message : String(err)) + '</p>';
      });
  }

  function hidePayloadModal() {
    var modal = document.getElementById('payload-modal');
    if (modal) modal.classList.remove('visible');
  }

  function setupPayloadModal() {
    var messagesEl = document.getElementById('messages');
    var closeBtn = document.getElementById('payload-modal-close');
    var overlay = document.getElementById('payload-modal');
    if (messagesEl) {
      messagesEl.addEventListener('click', function (e) {
        var row = e.target && e.target.closest && e.target.closest('tr.msg-row');
        if (row && row.dataset && row.dataset.messageId !== undefined) {
          showPayloadModal(row.dataset.messageId);
        }
      });
    }
    if (closeBtn) closeBtn.addEventListener('click', hidePayloadModal);
    if (overlay) {
      overlay.addEventListener('click', function (e) {
        if (e.target === overlay) hidePayloadModal();
      });
    }
  }

  function toErrorList(data) {
    if (Array.isArray(data)) return data;
    if (data && typeof data === 'object' && Array.isArray(data.errors)) return data.errors;
    if (data && typeof data === 'object' && Array.isArray(data.data)) return data.data;
    if (data && typeof data === 'object' && Array.isArray(data.result)) return data.result;
    return [];
  }

  function renderErrors(data) {
    lastErrors = data;
    const el = document.getElementById('errors');
    if (!el) return;
    const list = toErrorList(data);
    const sorted = list.slice().sort(function (a, b) {
      const ta = (a && a.timestamp) ? new Date(a.timestamp).getTime() : 0;
      const tb = (b && b.timestamp) ? new Date(b.timestamp).getTime() : 0;
      return tb - ta;
    });
    const ten = sorted.slice(0, 10);
    let html = '<table><thead><tr><th>id</th><th>message_id</th><th>error_class</th><th>detail</th><th>timestamp</th></tr></thead><tbody>';
    ten.forEach(function (e) {
      var id = e.id != null ? e.id : '';
      var msgId = e.message_id ?? e.messageId ?? '';
      var errClass = e.error_class ?? e.errorClass ?? '';
      var detail = e.detail ?? '';
      var ts = e.timestamp ?? '';
      html += '<tr><td>' + escapeHtml(String(id)) + '</td><td>' + escapeHtml(String(msgId)) + '</td><td>' + escapeHtml(String(errClass)) + '</td><td>' + escapeHtml(String(detail)) + '</td><td>' + escapeHtml(String(ts)) + '</td></tr>';
    });
    html += '</tbody></table>';
    el.innerHTML = html;
  }

  function escapeHtml(s) {
    const div = document.createElement('div');
    div.textContent = s;
    return div.innerHTML;
  }

  function formatMessageDetail(data) {
    if (data == null) return '<p>No data</p>';
    var parts = [];
    if (data.message_id) {
      parts.push('<h3 class="detail-section">Message</h3><table class="detail-table"><tbody>');
      if (data.message_id != null) parts.push('<tr><th>message_id</th><td>' + escapeHtml(String(data.message_id)) + '</td></tr>');
      if (data.status != null) parts.push('<tr><th>status</th><td>' + escapeHtml(String(data.status)) + '</td></tr>');
      if (data.received_at != null) parts.push('<tr><th>received_at</th><td>' + escapeHtml(String(data.received_at)) + '</td></tr>');
      if (data.message_type != null) parts.push('<tr><th>message_type</th><td>' + escapeHtml(String(data.message_type)) + '</td></tr>');
      if (data.control_id != null) parts.push('<tr><th>control_id</th><td>' + escapeHtml(String(data.control_id)) + '</td></tr>');
      parts.push('</tbody></table>');
    }
    var meta = data.metadata;
    if (meta && typeof meta === 'object') {
      parts.push('<h3 class="detail-section">Message metadata</h3><table class="detail-table"><tbody>');
      if (meta.sendingApplication != null) parts.push('<tr><th>sendingApplication</th><td>' + escapeHtml(String(meta.sendingApplication)) + '</td></tr>');
      if (meta.sendingFacility != null) parts.push('<tr><th>sendingFacility</th><td>' + escapeHtml(String(meta.sendingFacility)) + '</td></tr>');
      if (meta.receivingApplication != null) parts.push('<tr><th>receivingApplication</th><td>' + escapeHtml(String(meta.receivingApplication)) + '</td></tr>');
      if (meta.receivingFacility != null) parts.push('<tr><th>receivingFacility</th><td>' + escapeHtml(String(meta.receivingFacility)) + '</td></tr>');
      if (meta.messageType != null) parts.push('<tr><th>messageType</th><td>' + escapeHtml(String(meta.messageType)) + '</td></tr>');
      if (meta.messageControlId != null) parts.push('<tr><th>messageControlId</th><td>' + escapeHtml(String(meta.messageControlId)) + '</td></tr>');
      parts.push('</tbody></table>');
    }
    var demo = data.demographics;
    if (demo && typeof demo === 'object') {
      parts.push('<h3 class="detail-section">Patient demographics</h3><table class="detail-table"><tbody>');
      if (demo.patientId != null) parts.push('<tr><th>Patient ID</th><td>' + escapeHtml(String(demo.patientId)) + '</td></tr>');
      if (demo.familyName != null) parts.push('<tr><th>Family name</th><td>' + escapeHtml(String(demo.familyName)) + '</td></tr>');
      if (demo.givenName != null) parts.push('<tr><th>Given name</th><td>' + escapeHtml(String(demo.givenName)) + '</td></tr>');
      if (demo.dateOfBirth != null) parts.push('<tr><th>Date of birth</th><td>' + escapeHtml(String(demo.dateOfBirth)) + '</td></tr>');
      if (demo.gender != null) parts.push('<tr><th>Gender</th><td>' + escapeHtml(String(demo.gender)) + '</td></tr>');
      parts.push('</tbody></table>');
    } else {
      parts.push('<h3 class="detail-section">Patient demographics</h3><p class="detail-muted">No demographics for this message.</p>');
    }
    parts.push('<h3 class="detail-section">Raw JSON</h3><pre class="detail-json">' + escapeHtml(typeof data === 'string' ? data : JSON.stringify(data, null, 2)) + '</pre>');
    return parts.join('');
  }

  function setError(err) {
    lastError = err;
    const el = document.getElementById('connection-error');
    if (!el) return;
    el.textContent = err ? 'Connection error: ' + err.message : '';
    el.style.display = err ? 'block' : 'none';
  }

  function poll() {
    const base = getConfig().baseUrl;
    if (!base) {
      setError(new Error('baseUrl not configured'));
      return;
    }

    Promise.all([
      api('/health').catch(function (e) { return null; }),
      api('/metrics').catch(function (e) { return null; }),
      api('/messages?status=delivered').catch(function (e) { return []; }),
      api('/errors').catch(function (e) { return []; })
    ]).then(function (results) {
      setError(null);
      renderHealth(results[0]);
      renderMetrics(results[1]);
      renderMessages(results[2]);
      renderErrors(results[3]);
    }).catch(function (err) {
      setError(err);
      if (lastHealth != null) renderHealth(lastHealth);
      if (lastMetrics != null) renderMetrics(lastMetrics);
      if (lastMessages != null) renderMessages(lastMessages);
      if (lastErrors != null) renderErrors(lastErrors);
    });
  }

  function startPolling() {
    if (pollTimer) clearInterval(pollTimer);
    poll();
    const interval = Math.max(1, (getConfig().pollIntervalSeconds || 5)) * 1000;
    pollTimer = setInterval(poll, interval);
  }

  function init() {
    setupPayloadModal();
    loadConfig(function () {
      document.getElementById('api-url').textContent = getConfig().baseUrl;
      document.getElementById('poll-interval').textContent = getConfig().pollIntervalSeconds + 's';
      startPolling();
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
