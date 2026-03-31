'use strict';
'require form';
'require fs';
'require uci';
'require ui';
'require view';

return view.extend({
	load: function() {
		return Promise.all([uci.load('sbproxy')]);
	},
	render: function() {
		let m = new form.Map('sbproxy', _('Subscription'));
		let s = m.section(form.NamedSection, 'main', 'subscription', _('Subscription Import'));

		let o;
		o = s.option(form.Flag, 'enabled', _('Enable subscription importer'));
		o.default = '0';

		o = s.option(form.Value, 'url', _('Subscription URL'));
		o.rmempty = false;

		o = s.option(form.Value, 'user_agent', _('User-Agent'));
		o.default = 'SBProxy/0.2';

		o = s.option(form.Button, '_run', _('Import now'));
		o.inputtitle = _('Run');
		o.onclick = function() {
			return fs.exec('/usr/bin/ucode', ['-S', '/etc/sbproxy/scripts/update_subscriptions.uc']).then(function(res) {
				ui.addNotification(null, E('p', _('Subscription import finished. Check Nodes page.')));
			}).catch(function(err) {
				ui.addNotification(null, E('p', _('Subscription import failed: ') + err));
			});
		};

		return m.render();
	}
});
