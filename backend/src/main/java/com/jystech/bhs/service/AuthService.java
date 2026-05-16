package com.jystech.bhs.service;

import com.jystech.bhs.dto.AuthDtos;

public interface AuthService {
    AuthDtos.LoginResponse login(AuthDtos.LoginRequest request);
    AuthDtos.CaptchaResponse captcha();
}
