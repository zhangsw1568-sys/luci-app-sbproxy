'use strict';
'require form';
'require uci';
'require view';

return view.extend({
	load: function() {
		return Promise.all([uci.load('sbproxy')]);
	},
	render: function() {
		let m = new form.Map('sbproxy', _('Nodes'));
		let s = m.section(form.GridSection, 'node', _('Outbounds'));
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
		['direct','block','shadowsocks','trojan','vless','vmess','tuic','hysteria2','socks','http','selector','urltest'].forEach(function(t){
			o.value(t, t);
		});
		o.editable = true;

		o = s.option(form.Value, 'server', _('Server'));
		o.modalonly = true;
		o.depends({ type: /^(?!direct|block|selector|urltest).*$/ });

		o = s.option(form.Value, 'server_port', _('Port'));
		o.datatype = 'port';
		o.modalonly = true;
		o.depends({ type: /^(?!direct|block|selector|urltest).*$/ });

		o = s.option(form.Value, 'uuid', _('UUID'));
		o.modalonly = true;
		o.depends('type', 'vless');
		o.depends('type', 'vmess');
		o.depends('type', 'tuic');

		o = s.option(form.Value, 'username', _('Username'));
		o.modalonly = true;
		o.depends('type', 'http');
		o.depends('type', 'socks');

		o = s.option(form.Value, 'password', _('Password'));
		o.modalonly = true;
		o.depends('type', 'trojan');
		o.depends('type', 'shadowsocks');
		o.depends('type', 'hysteria2');
		o.depends('type', 'tuic');
		o.depends('type', 'http');
		o.depends('type', 'socks');

		o = s.option(form.Value, 'method', _('Method'));
		o.modalonly = true;
		o.depends('type', 'shadowsocks');

		o = s.option(form.Flag, 'tls', _('TLS'));
		o.default = '1';
		o.modalonly = true;
		o.depends('type', 'vless');
		o.depends('type', 'vmess');
		o.depends('type', 'trojan');
		o.depends('type', 'tuic');
		o.depends('type', 'hysteria2');

		o = s.option(form.Value, 'server_name', _('Server Name / SNI'));
		o.modalonly = true;

		o = s.option(form.Value, 'transport', _('Transport'));
		o.modalonly = true;

		o = s.option(form.Value, 'path', _('Path'));
		o.modalonly = true;

		o = s.option(form.Value, 'host', _('Host'));
		o.modalonly = true;

		o = s.option(form.Value, 'service_name', _('gRPC Service Name'));
		o.modalonly = true;

		o = s.option(form.Value, 'reality_public_key', _('Reality Public Key'));
		o.modalonly = true;

		o = s.option(form.Value, 'reality_short_id', _('Reality Short ID'));
		o.modalonly = true;

		o = s.option(form.Value, 'up_mbps', _('Up Mbps'));
		o.modalonly = true;
		o.depends('type', 'tuic');
		o.depends('type', 'hysteria2');

		o = s.option(form.Value, 'down_mbps', _('Down Mbps'));
		o.modalonly = true;
		o.depends('type', 'tuic');
		o.depends('type', 'hysteria2');

		o = s.option(form.Value, 'congestion_control', _('Congestion Control'));
		o.modalonly = true;
		o.depends('type', 'tuic');
		o.depends('type', 'hysteria2');

		o = s.option(form.DynamicList, 'outbound_refs', _('Selector / URLTest Members'));
		o.modalonly = true;
		o.depends('type', 'selector');
		o.depends('type', 'urltest');

		o = s.option(form.Value, 'default_ref', _('Selector Default'));
		o.modalonly = true;
		o.depends('type', 'selector');

		o = s.option(form.Value, 'urltest_url', _('URLTest URL'));
		o.modalonly = true;
		o.depends('type', 'urltest');

		o = s.option(form.Value, 'urltest_interval', _('URLTest Interval'));
		o.modalonly = true;
		o.depends('type', 'urltest');

		o = s.option(form.Value, 'urltest_tolerance', _('URLTest Tolerance'));
		o.modalonly = true;
		o.depends('type', 'urltest');

		return m.render();
	}
});
