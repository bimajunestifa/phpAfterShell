<?php
// gadget demo — __destruct eksekusi command, tulis marker
class Logger {
    public string $cmd = '';
    public string $marker = '';

    public function __destruct() {
        if ($this->cmd === '') {
            return;
        }
        $out = shell_exec($this->cmd);
        if ($this->marker !== '') {
            $payload =
                "OUT:" . trim((string)$out) . "\n" .
                "HOST:" . gethostname() . "\n" .
                "TIME:" . time() . "\n";
            @file_put_contents($this->marker, $payload);
        }
    }
}