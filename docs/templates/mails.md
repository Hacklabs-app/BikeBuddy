# Bike Buddy Transactional Email Templates

This file contains the complete, customized, ultra-premium transactional email templates for Bike Buddy. The designs use a high-fidelity, responsive layout tailored to Bike Buddy's brand: a sleek, modern, dark-slate background with vibrant emerald green accents, high-contrast readable typography, and polished rounded card layouts.

---

## 1. Confirm Signup

* **Subject Line**: Welcome to Bike Buddy! 🚲 Confirm Your Email
* **Plain Text Version**:
  ```text
  Welcome to Bike Buddy!

  We are thrilled to have you join our cycling community. Before you hit the road, please confirm your email address by visiting the link below:

  Confirm Your Email: {{ .ConfirmationURL }}

  If you did not sign up for Bike Buddy, you can safely ignore this email.

  Happy cycling,
  The Bike Buddy Team
  ```

* **HTML Version**:
  ```html
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Confirm Your Signup</title>
  </head>
  <body style="margin: 0; padding: 0; background-color: #0b1329; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; color: #f3f4f6;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color: #0b1329; min-height: 100vh; padding: 40px 20px;">
      <tr>
        <td align="center" valign="top">
          <!-- Card Container -->
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width: 500px; background-color: #131c30; border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 16px; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3); overflow: hidden;">
            <!-- Header/Logo Section -->
            <tr>
              <td style="padding: 32px 32px 16px 32px; text-align: center;">
                <span style="font-size: 40px;">🚲</span>
                <h1 style="margin: 16px 0 0 0; font-size: 24px; font-weight: 700; color: #10b981; letter-spacing: -0.5px;">Bike Buddy</h1>
              </td>
            </tr>
            <!-- Content Section -->
            <tr>
              <td style="padding: 16px 32px 32px 32px; text-align: center;">
                <h2 style="margin: 0 0 12px 0; font-size: 20px; font-weight: 600; color: #ffffff;">Confirm Your Signup</h2>
                <p style="margin: 0 0 24px 0; font-size: 15px; line-height: 1.6; color: #9ca3af;">
                  Welcome to the ultimate cycling companion! Follow the link below to confirm your account and start planning your perfect ride.
                </p>
                <!-- Call To Action Button -->
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin: 0 auto 28px auto;">
                  <tr>
                    <td align="center" style="border-radius: 8px; background-color: #10b981;">
                      <a href="{{ .ConfirmationURL }}" target="_blank" style="display: inline-block; padding: 12px 32px; font-size: 15px; font-weight: 600; color: #ffffff; text-decoration: none; border-radius: 8px; transition: background-color 0.2s ease;">Confirm Your Email</a>
                    </td>
                  </tr>
                </table>
                <p style="margin: 0 0 8px 0; font-size: 12px; color: #6b7280;">
                  If the button doesn't work, copy and paste the link below into your browser:
                </p>
                <p style="margin: 0; font-size: 12px; word-break: break-all; color: #10b981;">
                  <a href="{{ .ConfirmationURL }}" style="color: #10b981; text-decoration: underline;">{{ .ConfirmationURL }}</a>
                </p>
              </td>
            </tr>
            <!-- Footer Section -->
            <tr>
              <td style="padding: 24px 32px; background-color: #0d172a; text-align: center; border-top: 1px solid rgba(255, 255, 255, 0.05);">
                <p style="margin: 0 0 8px 0; font-size: 12px; color: #6b7280;">
                  This is an automated security email from Bike Buddy.
                </p>
                <p style="margin: 0; font-size: 11px; color: #4b5563;">
                  If you didn't create a Bike Buddy account, you can safely disregard this email.
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
  </html>
  ```

---

## 2. Invited User

* **Subject Line**: You've been invited to join Bike Buddy! 🎉
* **Plain Text Version**:
  ```text
  You have been invited!

  You have been invited to create a user on {{ .SiteURL }}. Follow the link below to accept the invitation and set up your profile:

  Accept the Invite: {{ .ConfirmationURL }}

  We can't wait to see you on the road!

  Cheers,
  The Bike Buddy Team
  ```

* **HTML Version**:
  ```html
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>You Have Been Invited</title>
  </head>
  <body style="margin: 0; padding: 0; background-color: #0b1329; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; color: #f3f4f6;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color: #0b1329; min-height: 100vh; padding: 40px 20px;">
      <tr>
        <td align="center" valign="top">
          <!-- Card Container -->
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width: 500px; background-color: #131c30; border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 16px; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3); overflow: hidden;">
            <!-- Header/Logo Section -->
            <tr>
              <td style="padding: 32px 32px 16px 32px; text-align: center;">
                <span style="font-size: 40px;">🎉</span>
                <h1 style="margin: 16px 0 0 0; font-size: 24px; font-weight: 700; color: #10b981; letter-spacing: -0.5px;">Bike Buddy</h1>
              </td>
            </tr>
            <!-- Content Section -->
            <tr>
              <td style="padding: 16px 32px 32px 32px; text-align: center;">
                <h2 style="margin: 0 0 12px 0; font-size: 20px; font-weight: 600; color: #ffffff;">You Have Been Invited</h2>
                <p style="margin: 0 0 24px 0; font-size: 15px; line-height: 1.6; color: #9ca3af;">
                  You have been invited to create a user account on <strong style="color: #ffffff;">{{ .SiteURL }}</strong>. Click the link below to accept the invitation and begin your journey.
                </p>
                <!-- Call To Action Button -->
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin: 0 auto 28px auto;">
                  <tr>
                    <td align="center" style="border-radius: 8px; background-color: #10b981;">
                      <a href="{{ .ConfirmationURL }}" target="_blank" style="display: inline-block; padding: 12px 32px; font-size: 15px; font-weight: 600; color: #ffffff; text-decoration: none; border-radius: 8px; transition: background-color 0.2s ease;">Accept the Invite</a>
                    </td>
                  </tr>
                </table>
                <p style="margin: 0 0 8px 0; font-size: 12px; color: #6b7280;">
                  If the button doesn't work, copy and paste the link below into your browser:
                </p>
                <p style="margin: 0; font-size: 12px; word-break: break-all; color: #10b981;">
                  <a href="{{ .ConfirmationURL }}" style="color: #10b981; text-decoration: underline;">{{ .ConfirmationURL }}</a>
                </p>
              </td>
            </tr>
            <!-- Footer Section -->
            <tr>
              <td style="padding: 24px 32px; background-color: #0d172a; text-align: center; border-top: 1px solid rgba(255, 255, 255, 0.05);">
                <p style="margin: 0 0 8px 0; font-size: 12px; color: #6b7280;">
                  This invitation link is personal to you.
                </p>
                <p style="margin: 0; font-size: 11px; color: #4b5563;">
                  If you did not expect this invitation, you can safely ignore this email.
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
  </html>
  ```

---

## 3. Magic Link

* **Subject Line**: Your Secure Login Link for Bike Buddy ⚡
* **Plain Text Version**:
  ```text
  Your Bike Buddy Magic Link

  Follow the secure link below to log in instantly to your Bike Buddy account. This link will log you in automatically:

  Log In to Your Account: {{ .ConfirmationURL }}

  For your security, please do not share this link with anyone.

  Ride safe,
  The Bike Buddy Team
  ```

* **HTML Version**:
  ```html
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Magic Link Login</title>
  </head>
  <body style="margin: 0; padding: 0; background-color: #0b1329; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; color: #f3f4f6;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color: #0b1329; min-height: 100vh; padding: 40px 20px;">
      <tr>
        <td align="center" valign="top">
          <!-- Card Container -->
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width: 500px; background-color: #131c30; border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 16px; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3); overflow: hidden;">
            <!-- Header/Logo Section -->
            <tr>
              <td style="padding: 32px 32px 16px 32px; text-align: center;">
                <span style="font-size: 40px;">⚡</span>
                <h1 style="margin: 16px 0 0 0; font-size: 24px; font-weight: 700; color: #10b981; letter-spacing: -0.5px;">Bike Buddy</h1>
              </td>
            </tr>
            <!-- Content Section -->
            <tr>
              <td style="padding: 16px 32px 32px 32px; text-align: center;">
                <h2 style="margin: 0 0 12px 0; font-size: 20px; font-weight: 600; color: #ffffff;">Magic Link Login</h2>
                <p style="margin: 0 0 24px 0; font-size: 15px; line-height: 1.6; color: #9ca3af;">
                  No passwords required! Click the secure button below to log in directly to your Bike Buddy account.
                </p>
                <!-- Call To Action Button -->
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin: 0 auto 28px auto;">
                  <tr>
                    <td align="center" style="border-radius: 8px; background-color: #10b981;">
                      <a href="{{ .ConfirmationURL }}" target="_blank" style="display: inline-block; padding: 12px 32px; font-size: 15px; font-weight: 600; color: #ffffff; text-decoration: none; border-radius: 8px; transition: background-color 0.2s ease;">Log In</a>
                    </td>
                  </tr>
                </table>
                <p style="margin: 0 0 8px 0; font-size: 12px; color: #6b7280;">
                  If the button doesn't work, copy and paste the link below into your browser:
                </p>
                <p style="margin: 0; font-size: 12px; word-break: break-all; color: #10b981;">
                  <a href="{{ .ConfirmationURL }}" style="color: #10b981; text-decoration: underline;">{{ .ConfirmationURL }}</a>
                </p>
              </td>
            </tr>
            <!-- Footer Section -->
            <tr>
              <td style="padding: 24px 32px; background-color: #0d172a; text-align: center; border-top: 1px solid rgba(255, 255, 255, 0.05);">
                <p style="margin: 0 0 8px 0; font-size: 12px; color: #6b7280;">
                  This is a single-use secure login link.
                </p>
                <p style="margin: 0; font-size: 11px; color: #4b5563;">
                  If you didn't request a magic link, you can safely delete this email.
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
  </html>
  ```

---

## 4. Confirm Change of Email

* **Subject Line**: Confirm Your Email Update - Bike Buddy 🛡️
* **Plain Text Version**:
  ```text
  Confirm Change of Email

  We received a request to change your Bike Buddy account email address from {{ .Email }} to {{ .NewEmail }}.

  Please click the link below to verify this change:

  Confirm Email Update: {{ .ConfirmationURL }}

  If you did not request this update, please secure your account immediately.

  Best,
  The Bike Buddy Security Team
  ```

* **HTML Version**:
  ```html
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Confirm Change of Email</title>
  </head>
  <body style="margin: 0; padding: 0; background-color: #0b1329; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; color: #f3f4f6;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color: #0b1329; min-height: 100vh; padding: 40px 20px;">
      <tr>
        <td align="center" valign="top">
          <!-- Card Container -->
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width: 500px; background-color: #131c30; border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 16px; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3); overflow: hidden;">
            <!-- Header/Logo Section -->
            <tr>
              <td style="padding: 32px 32px 16px 32px; text-align: center;">
                <span style="font-size: 40px;">🛡️</span>
                <h1 style="margin: 16px 0 0 0; font-size: 24px; font-weight: 700; color: #10b981; letter-spacing: -0.5px;">Bike Buddy</h1>
              </td>
            </tr>
            <!-- Content Section -->
            <tr>
              <td style="padding: 16px 32px 32px 32px; text-align: center;">
                <h2 style="margin: 0 0 12px 0; font-size: 20px; font-weight: 600; color: #ffffff;">Confirm Email Change</h2>
                <p style="margin: 0 0 20px 0; font-size: 15px; line-height: 1.6; color: #9ca3af;">
                  We received a request to update the email address linked to your account from <strong style="color: #9ca3af;">{{ .Email }}</strong> to <strong style="color: #ffffff;">{{ .NewEmail }}</strong>.
                </p>
                <p style="margin: 0 0 24px 0; font-size: 14px; line-height: 1.6; color: #f87171;">
                  Please confirm this update by clicking the button below:
                </p>
                <!-- Call To Action Button -->
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin: 0 auto 28px auto;">
                  <tr>
                    <td align="center" style="border-radius: 8px; background-color: #10b981;">
                      <a href="{{ .ConfirmationURL }}" target="_blank" style="display: inline-block; padding: 12px 32px; font-size: 15px; font-weight: 600; color: #ffffff; text-decoration: none; border-radius: 8px; transition: background-color 0.2s ease;">Change Email</a>
                    </td>
                  </tr>
                </table>
                <p style="margin: 0 0 8px 0; font-size: 12px; color: #6b7280;">
                  If the button doesn't work, copy and paste the link below into your browser:
                </p>
                <p style="margin: 0; font-size: 12px; word-break: break-all; color: #10b981;">
                  <a href="{{ .ConfirmationURL }}" style="color: #10b981; text-decoration: underline;">{{ .ConfirmationURL }}</a>
                </p>
              </td>
            </tr>
            <!-- Footer Section -->
            <tr>
              <td style="padding: 24px 32px; background-color: #0d172a; text-align: center; border-top: 1px solid rgba(255, 255, 255, 0.05);">
                <p style="margin: 0 0 8px 0; font-size: 12px; color: #6b7280;">
                  Security alert: If you did not request this update, please change your password and contact support.
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
  </html>
  ```

---

## 5. Reset Password

* **Subject Line**: Reset Your Bike Buddy Password 🔑
* **Plain Text Version**:
  ```text
  Reset Your Bike Buddy Password

  We received a request to reset the password for your Bike Buddy account. Follow the secure link below to establish a new password:

  Reset Password: {{ .ConfirmationURL }}

  If you did not request a password reset, you can safely ignore this email. Your current password will remain secure.

  Best regards,
  The Bike Buddy Support Team
  ```

* **HTML Version**:
  ```html
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Your Password</title>
  </head>
  <body style="margin: 0; padding: 0; background-color: #0b1329; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; color: #f3f4f6;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color: #0b1329; min-height: 100vh; padding: 40px 20px;">
      <tr>
        <td align="center" valign="top">
          <!-- Card Container -->
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width: 500px; background-color: #131c30; border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 16px; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3); overflow: hidden;">
            <!-- Header/Logo Section -->
            <tr>
              <td style="padding: 32px 32px 16px 32px; text-align: center;">
                <span style="font-size: 40px;">🔑</span>
                <h1 style="margin: 16px 0 0 0; font-size: 24px; font-weight: 700; color: #10b981; letter-spacing: -0.5px;">Bike Buddy</h1>
              </td>
            </tr>
            <!-- Content Section -->
            <tr>
              <td style="padding: 16px 32px 32px 32px; text-align: center;">
                <h2 style="margin: 0 0 12px 0; font-size: 20px; font-weight: 600; color: #ffffff;">Reset Password</h2>
                <p style="margin: 0 0 24px 0; font-size: 15px; line-height: 1.6; color: #9ca3af;">
                  We received a request to reset the password for your user account. Click the secure link below to set up a new password.
                </p>
                <!-- Call To Action Button -->
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin: 0 auto 28px auto;">
                  <tr>
                    <td align="center" style="border-radius: 8px; background-color: #10b981;">
                      <a href="{{ .ConfirmationURL }}" target="_blank" style="display: inline-block; padding: 12px 32px; font-size: 15px; font-weight: 600; color: #ffffff; text-decoration: none; border-radius: 8px; transition: background-color 0.2s ease;">Reset Password</a>
                    </td>
                  </tr>
                </table>
                <p style="margin: 0 0 8px 0; font-size: 12px; color: #6b7280;">
                  If the button doesn't work, copy and paste the link below into your browser:
                </p>
                <p style="margin: 0; font-size: 12px; word-break: break-all; color: #10b981;">
                  <a href="{{ .ConfirmationURL }}" style="color: #10b981; text-decoration: underline;">{{ .ConfirmationURL }}</a>
                </p>
              </td>
            </tr>
            <!-- Footer Section -->
            <tr>
              <td style="padding: 24px 32px; background-color: #0d172a; text-align: center; border-top: 1px solid rgba(255, 255, 255, 0.05);">
                <p style="margin: 0 0 8px 0; font-size: 12px; color: #6b7280;">
                  If you didn't request a password reset, you can safely ignore this email.
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
  </html>
  ```

---

## 6. Confirm Reauthentication

* **Subject Line**: Your Bike Buddy Security Code: {{ .Token }} 🛡️
* **Plain Text Version**:
  ```text
  Confirm Reauthentication

  To verify your identity and authorize this transaction or setting change, please enter the security token below on your device:

  Security Code: {{ .Token }}

  For your security, do not share this token with anyone.

  Stay safe,
  The Bike Buddy Security Team
  ```

* **HTML Version**:
  ```html
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Confirm Reauthentication</title>
  </head>
  <body style="margin: 0; padding: 0; background-color: #0b1329; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; color: #f3f4f6;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color: #0b1329; min-height: 100vh; padding: 40px 20px;">
      <tr>
        <td align="center" valign="top">
          <!-- Card Container -->
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width: 500px; background-color: #131c30; border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 16px; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3); overflow: hidden;">
            <!-- Header/Logo Section -->
            <tr>
              <td style="padding: 32px 32px 16px 32px; text-align: center;">
                <span style="font-size: 40px;">🛡️</span>
                <h1 style="margin: 16px 0 0 0; font-size: 24px; font-weight: 700; color: #10b981; letter-spacing: -0.5px;">Bike Buddy</h1>
              </td>
            </tr>
            <!-- Content Section -->
            <tr>
              <td style="padding: 16px 32px 32px 32px; text-align: center;">
                <h2 style="margin: 0 0 12px 0; font-size: 20px; font-weight: 600; color: #ffffff;">Confirm Reauthentication</h2>
                <p style="margin: 0 0 24px 0; font-size: 15px; line-height: 1.6; color: #9ca3af;">
                  Please enter the security verification token below in the Bike Buddy application to complete your request:
                </p>
                <!-- Verification Code Badge -->
                <div style="display: inline-block; margin: 0 auto 28px auto; padding: 14px 28px; background-color: rgba(16, 185, 129, 0.1); border: 1px dashed #10b981; border-radius: 8px;">
                  <span style="font-family: 'Courier New', Courier, monospace; font-size: 28px; font-weight: 700; color: #10b981; letter-spacing: 4px;">{{ .Token }}</span>
                </div>
                <p style="margin: 0; font-size: 13px; color: #6b7280; line-height: 1.5;">
                  This code expires shortly. Never share your security code with anyone.
                </p>
              </td>
            </tr>
            <!-- Footer Section -->
            <tr>
              <td style="padding: 24px 32px; background-color: #0d172a; text-align: center; border-top: 1px solid rgba(255, 255, 255, 0.05);">
                <p style="margin: 0; font-size: 11px; color: #4b5563;">
                  If you didn't initiate this action, please secure your account immediately.
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
  </html>
  ```
