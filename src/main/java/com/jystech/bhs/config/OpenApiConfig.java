package com.jystech.bhs.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {
    @Bean
    OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info().title("BHARATHI JHARIJANA SANGAM API").version("v1"))
                .servers(List.of(new Server().url("https://meghaconnect.cloud:8085/api/v1")));
    }
}
