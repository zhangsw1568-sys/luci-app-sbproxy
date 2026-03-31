#!/usr/bin/ucode
'use strict';

import { writefile } from 'fs';
import { cursor } from 'uci';
import {
	RUN_DIR, strToBool, strToInt, strToTime, removeBlankAttrs
} from '/etc/sbproxy/scripts/sbproxy.uc';

const uci = cursor();
const uciconfig = 'sbproxy';
uci.load(uciconfig);

const cfg = uci.get_all(uciconfig, 'config') || {};
const default_dns_ref = cfg.default_dns_server || 'wan_dns';

function node_tag(section) {
	return section.label || ('node-' + section['.name']);
}

function dns_tag(section) {
	return section.label || ('dns-' + section['.name']);
}

function generate_dns_server(s) {
	let obj = {
		tag: dns_tag(s),
		type: s.type || 'udp',
		server: s.server,
		server_port: strToInt(s.server_port),
		path: s.path,
		detour: s.detour || 'direct-out'
	};

	if ((s.type in ['https', 'tls', 'quic', 'h3']) && s.server && !(s.server ~ /^(\d+\.){3}\d+$/))
		obj.domain_resolver = dns_tag(uci.get_all(uciconfig, 'wan_dns') || { label: 'wan-dns', '.name': 'wan_dns' });

	return obj;
}

function generate_node(s) {
	let tag = node_tag(s);

	if (s.type === 'selector' || s.type === 'urltest') {
		let outbounds = [];
		if (s.outbound_refs)
			for (let ref in s.outbound_refs) {
				const target = uci.get_all(uciconfig, ref);
				if (target && target.enabled !== '0')
					push(outbounds, node_tag(target));
			}
		return {
			type: s.type,
			tag: tag,
			outbounds: outbounds,
			default: s.default_ref ? node_tag(uci.get_all(uciconfig, s.default_ref) || {}) : null,
			url: s.urltest_url || 'https://www.gstatic.com/generate_204',
			interval: strToTime(s.urltest_interval || '300'),
			tolerance: strToInt(s.urltest_tolerance || '50'),
			interrupt_exist_connections: strToBool(s.interrupt_exist_connections || '0')
		};
	}

	if (s.type === 'direct' || s.type === 'block')
		return { type: s.type, tag: tag };

	let o = {
		type: s.type,
		tag: tag,
		server: s.server,
		server_port: strToInt(s.server_port),
		uuid: s.uuid,
		username: s.username,
		password: s.password,
		method: s.method,
		flow: s.flow,
		congestion_control: s.congestion_control,
		udp_relay_mode: s.udp_relay_mode,
		up_mbps: strToInt(s.up_mbps),
		down_mbps: strToInt(s.down_mbps),
		tls: strToBool(s.tls) ? {
			enabled: true,
			server_name: s.server_name,
			insecure: strToBool(s.insecure),
			alpn: s.alpn ? split(s.alpn, ',') : null,
			utls: s.utls ? {
				enabled: true,
				fingerprint: s.utls
			} : null,
			reality: (s.reality_public_key) ? {
				enabled: true,
				public_key: s.reality_public_key,
				short_id: s.reality_short_id
			} : null
		} : null,
		transport: s.transport ? {
			type: s.transport,
			host: s.host,
			path: s.path,
			service_name: s.service_name,
			headers: s.ws_host ? { Host: s.ws_host } : null
		} : null
	};

	return o;
}

let selected_main = uci.get_all(uciconfig, cfg.main_node || '') || {};
let final_outbound = selected_main['.name'] ? node_tag(selected_main) : 'direct-out';

const config = {
	log: {
		level: cfg.log_level || 'warn',
		timestamp: true
	},
	dns: {
		servers: [],
		rules: [
			{ inbound: 'dns-in', action: 'hijack-dns' }
		],
		final: dns_tag(uci.get_all(uciconfig, default_dns_ref) || { label: 'wan-dns', '.name': 'wan_dns' })
	},
	inbounds: [
		{ type: 'direct', tag: 'dns-in', listen: '::', listen_port: strToInt(cfg.dns_port || '1053') },
		{ type: 'mixed', tag: 'mixed-in', listen: '::', listen_port: strToInt(cfg.mixed_port || '7890') }
	],
	outbounds: [],
	route: {
		rules: [
			{ inbound: 'dns-in', action: 'hijack-dns' },
			{ action: 'sniff' }
		],
		final: final_outbound
	},
	experimental: {}
};

if (strToBool(cfg.clash_api_enabled)) {
	config.experimental.clash_api = {
		external_controller: cfg.clash_api_controller || '0.0.0.0:9090',
		external_ui: cfg.clash_api_ui || 'dashboard',
		default_mode: 'Rule',
		access_control_allow_private_network: true
	};
}

uci.foreach(uciconfig, 'dns_server', (s) => {
	if (s.enabled === '0')
		return;
	push(config.dns.servers, generate_dns_server(s));
});

uci.foreach(uciconfig, 'node', (s) => {
	if (s.enabled === '0')
		return;
	push(config.outbounds, generate_node(s));
});

system('mkdir -p ' + RUN_DIR);
writefile(RUN_DIR + '/sing-box.json', sprintf('%.J\n', removeBlankAttrs(config)));
