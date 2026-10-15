/*
 * 外链直跳 (redirect-skip)
 *
 * Surge http-request script: 拦截国内常见的站外跳转确认页,
 * 从 query 参数里解析出真实目标地址, 直接 302 跳过去,
 * 省掉 "您即将离开本站, 是否继续访问" 这一步.
 *
 * 覆盖: 知乎 / 掘金 / 简书 / CSDN / Gitee / 微博 / 豆瓣 / B站 /
 *       少数派 / 优设 / 爱发电 / 力扣 / 企查查 / 天眼查 / 爱企查 /
 *       51CTO / Pixiv / 贴吧 / 搜狗 / 站长之家 / OSCHINA / pc6 /
 *       QQ邮箱 / QQ中转 / 腾讯文档 / 印象笔记 / YouTube / 微信开放社区 /
 *       企业微信确认页 (open.work.weixin.qq.com)
 *
 * 原理见同目录 ../Redirect_skip.sgmodule
 */

(function () {
  // 特定 host 优先尝试的参数名 (按顺序)
  var HOST_KEYS = [
    [/open\.work\.weixin\.qq\.com/i, ["uri"]],
    [/developers\.weixin\.qq\.com/i, ["href"]],
    [/weixin110\.qq\.com/i, ["url"]],
    [/(^|\.)weibo\.cn$/i, ["u", "toasturl", "url"]],
    [/mail\.qq\.com/i, ["url", "gourl"]],
    [/c\.pc\.qq\.com/i, ["pfurl"]],
    [/docs\.qq\.com/i, ["url"]],
    [/app\.yinxiang\.com/i, ["dest"]],
    [/youtube\.com/i, ["q"]],
    [/douban\.com/i, ["url"]],
    [/jianshu\.com/i, ["url", "t", "target", "to"]],
    [/qcc\.com/i, ["link"]],
    [/uisdc\.com/i, ["redirect"]],
    [/bilibili\.com/i, ["goto"]],
    [/bdimg\.com/i, ["url", "u"]],
    [/sogou\.com/i, ["url"]],
    [/pc6\.com/i, ["gourl"]],
  ];

  // 通用兜底参数名
  var GENERIC_KEYS = [
    "target",
    "url",
    "uri",
    "u",
    "link",
    "goto",
    "redirect",
    "to",
    "dest",
    "href",
    "q",
    "pfurl",
    "gourl",
    "toasturl",
    "t",
  ];

  function getParam(url, name) {
    var m = url.match(new RegExp("[?&#]" + name + "=([^&#]*)", "i"));
    return m ? m[1] : null;
  }

  // 有些站会做双重编码, 最多解 3 层; 解出来不变或非法就停
  function safeDecode(s) {
    var out = s;
    for (var i = 0; i < 3; i++) {
      if (/%[0-9A-Fa-f]{2}/.test(out)) {
        try {
          var d = decodeURIComponent(out);
          if (d === out) break;
          out = d;
        } catch (e) {
          break;
        }
      } else {
        break;
      }
    }
    return out;
  }

  function isHttpUrl(s) {
    // 只放行 http(s), 拒绝 javascript:/data: 等伪协议, 防止被确认页当跳板
    return /^https?:\/\/[^/\s?#]+\.[^/\s?#]+/i.test(s);
  }

  function resolve(url) {
    var host = "";
    var hm = url.match(/^https?:\/\/([^/?#]+)/i);
    if (hm) host = hm[1];

    var keys = [];
    for (var i = 0; i < HOST_KEYS.length; i++) {
      if (HOST_KEYS[i][0].test(host)) keys = keys.concat(HOST_KEYS[i][1]);
    }
    keys = keys.concat(GENERIC_KEYS);

    var seen = {};
    var k, raw, target;
    for (var j = 0; j < keys.length; j++) {
      k = keys[j].toLowerCase();
      if (seen[k]) continue;
      seen[k] = true;
      raw = getParam(url, keys[j]);
      if (raw) {
        target = safeDecode(raw).trim();
        if (isHttpUrl(target)) return target;
      }
    }

    // 兜底 1: 遍历所有参数值 (含 hash 里的), 哪个像 URL 就用哪个;
    // 兜底 2: 无参数名的裸编码 URL, 如 pixiv jump.php?https%3A%2F%2F...
    var parts = url.split(/[?&#]/).slice(1);
    for (var p = 0; p < parts.length; p++) {
      var v = parts[p];
      var eq = v.indexOf("=");
      if (eq >= 0) v = v.slice(eq + 1);
      if (!v) continue;
      target = safeDecode(v).trim();
      if (isHttpUrl(target)) return target;
    }

    return null;
  }

  try {
    var target = resolve($request.url);
    if (target && target !== $request.url) {
      $done({
        response: { status: 302, headers: { Location: target }, body: "" },
      });
    } else {
      $done({});
    }
  } catch (e) {
    $done({});
  }
})();
