package com.jystech.bhs.security;

import com.jystech.bhs.entity.Staff;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
public class JwtUtil {
    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private long expiration;

    public String generateToken(Staff staff) {
        Date now = new Date();
        return Jwts.builder()
                .subject(staff.getAdminId())
                .claim("role", staff.getRole().name())
                .claim("staffId", staff.getId())
                .issuedAt(now)
                .expiration(new Date(now.getTime() + expiration))
                .signWith(key())
                .compact();
    }

    public String username(String token) {
        return claims(token).getSubject();
    }

    public boolean valid(String token) {
        return claims(token).getExpiration().after(new Date());
    }

    private Claims claims(String token) {
        return Jwts.parser().verifyWith(key()).build().parseSignedClaims(token).getPayload();
    }

    private SecretKey key() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }
}
