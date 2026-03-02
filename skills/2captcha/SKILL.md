# 2captcha Skill

Solve CAPTCHAs programmatically using the 2Captcha human-powered service via CLI.

## Description

This skill allows you to bypass CAPTCHAs during web automation, account creation, or form submission. It uses the `solve-captcha` CLI tool which connects to the 2Captcha API.

## Requirements

- 2Captcha API Key (configured in `TWOCAPTCHA_API_KEY` environment variable)
- Internet connection

## Usage

The tool is available as `2captcha` in the MCP toolset. The command maps to `solve-captcha`.

### Check Balance

```bash
solve-captcha balance
```

### Image CAPTCHA

From URL:
```bash
solve-captcha image "https://site.com/captcha.jpg"
```

With options:
```bash
solve-captcha image "https://site.com/captcha.jpg" --numeric 1 --math
solve-captcha image "https://site.com/captcha.jpg" --comment "Enter red letters only"
```

### reCAPTCHA v2

```bash
solve-captcha recaptcha2 --sitekey "6Le-wvk..." --url "https://example.com"
```

### reCAPTCHA v3

```bash
solve-captcha recaptcha3 --sitekey "KEY" --url "URL" --action "submit" --min-score 0.7
```

### hCaptcha

```bash
solve-captcha hcaptcha --sitekey "KEY" --url "URL"
```

### Cloudflare Turnstile

```bash
solve-captcha turnstile --sitekey "0x4AAA..." --url "URL"
```

### FunCaptcha (Arkose)

```bash
solve-captcha funcaptcha --public-key "KEY" --url "URL"
```

### GeeTest

v3:
```bash
solve-captcha geetest --gt "GT" --challenge "CHALLENGE" --url "URL"
```

v4:
```bash
solve-captcha geetest4 --captcha-id "ID" --url "URL"
```

### Text Question

```bash
solve-captcha text "What color is the sky?" --lang en
```

## Finding CAPTCHA Parameters

- **reCAPTCHA sitekey**: Look for `data-sitekey` in HTML or `k=` parameter in iframe URL.
- **hCaptcha sitekey**: Look for `data-sitekey` in hCaptcha div.
- **Turnstile sitekey**: Look for `data-sitekey` in Turnstile widget.

## Cost

- Image: ~$0.001 per solve
- reCAPTCHA/hCaptcha/Turnstile: ~$0.003 per solve

## Error Handling

- `ERROR_ZERO_BALANCE`: Top up account.
- `ERROR_NO_SLOT_AVAILABLE`: Retry in a few seconds.
- `ERROR_CAPTCHA_UNSOLVABLE`: Bad image or impossible captcha.
