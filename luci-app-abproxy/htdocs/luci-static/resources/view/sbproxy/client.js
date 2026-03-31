'use strict';
'require form';
'require uci';
'require view';
'require sbproxy as sb';

return view.extend({
	load: function() {
		return Promise.all([uci.load('sbproxy')]);
	},
	render: function() {
		let m = new form.Map('sbproxy', _('SBProxy'), _('Second-step starter with subscription, DNS and more complete client fields.'));
		let s = m.section(form.NamedSection, 'config', 'sbproxy', _('Client Settings'));

		let o;
		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = '0';

		o = s.option(form.ListValue, 'proxy_mode', _('Proxy Mode'));
		o.value('redirect_tproxy', _('Redirect TCP + TProxy UDP'));
		o.value('tun', _('TUN'));
		o.default = 'redirect_tproxy';

		o = s.option(form.Value, 'mixed_port', _('HTTP(S)&SOCKS5 Mixed Port'));
		o.datatype = 'port';
		o.default = '7890';

		o = s.option(form.Value, 'dns_port', _('DNS Listen Port'));
		o.datatype = 'port';
		o.default = '1053';

		o = s.option(form.ListValue, 'main_node', _('Main Node'));
		uci.sections('sbproxy', 'node', function(n) {
			if (n.enabled !== '0')
				o.value(n['.name'], sb.nodeLabel(n));
		});
		o.default = 'direct_default';

		o = s.option(form.Flag, 'clash_api_enabled', _('Enable Clash API'));
		o.default = '1';

		o = s.option(form.Value, 'clash_api_controller', _('Clash API Controller'));
		o.default = '0.0.0.0:9090';

		o = s.option(form.Value, 'clash_api_ui', _('Clash API UI directory'));
		o.default = 'dashboard';

		o = s.option(form.ListValue, 'default_dns_server', _('Default DNS Server'));
		uci.sections('sbproxy', 'dns_server', function(ds) {
			if (ds.enabled !== '0')
				o.value(ds['.name'], sb.dnsLabel(ds));
		});
		o.default = 'wan_dns';

		return m.render();
	}
});
