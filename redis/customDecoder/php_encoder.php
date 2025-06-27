<?php
/*
 * @Author: 楚人不服周 lampardhuang@foxmail.com
 * @Date: 2025-06-25 10:04:50
 * @LastEditors: 楚人不服周 lampardhuang@foxmail.com
 * @LastEditTime: 2025-06-26 14:08:19
 * @FilePath: /service/redis/customDecoder/php_decoder.php
 * @Description: redis php 编码器
 * 参考文档 https://redis.tinycraft.cc/zh/guide/custom-decoder/
 */
$decoded = base64_decode($argv[1]);
if ($decoded !== false) {
    $json = json_decode($decoded, true);
    if ($json !== false) {
        $serialized = serialize($json);
        if ($serialized !== false) {
            echo base64_encode($serialized);
            return;
        }
    }
}
echo '[RDM-ERROR]';