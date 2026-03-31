'use strict';
'require form';
'require uci';
'require view';

return view.extend({
	load: function() {
		return Promise.all([uci.load('sbproxy')]);
	},
	render: function() {
		let m = new form.Map('sbproxy', _('DNS Servers'));
		let s = m.section(form.GridSection, 'dns_server', _('DNS Servers'));
		s.addremove = true;
		s.sortable = true;
		s.nodescriptions = true;

		let o;
		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = '1';
		o.editable = true;

		o = s.option(form.Value, 'label', _('Label'));
		o.editable = true;

		o = s.option(form.ListValue, 'type', _('Type'));
		['udp','tcp','tls','https','quic','h3'].forEach(function(t){ o.value(t, t); });
		o.default = 'udp';
		o.editable = true;

		o = s.option(form.Value, 'server', _('Server'));
		o.modalonly = true;

		o = s.option(form.Value, 'server_port', _('Port'));
		o.datatype = 'port';
		o.modalonly = true;

		o = s.option(form.Value, 'path', _('Path'));
		o.modalonly = true;
		o.depends('type', 'https');
		o.depends('type', 'h3');

		o = s.option(form.ListValue, 'detour', _('Outbound'));
		o.value('direct-out', 'direct-out');
		uci.sections('sbproxy', 'node', function(n) {
			if (n.enabled !== '0')
				o.value(n.label || n['.name'], n.label || n['.name']);
		});
		o.default = 'direct-out';
		o.modalonly = true;

		return m.render();
	}
});
