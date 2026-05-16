package com.jystech.bhs.util;

public final class AddressParser {
    private AddressParser() {
    }

    public static ParsedAddress parse(String address) {
        String value = clean(address);
        if (value.isEmpty()) {
            return new ParsedAddress("", "");
        }
        int comma = value.indexOf(',');
        if (comma < 0) {
            return new ParsedAddress(value, "");
        }
        String houseNo = value.substring(0, comma).trim();
        String area = value.substring(comma + 1).trim();
        return new ParsedAddress(houseNo, area);
    }

    public static String clean(String value) {
        return value == null ? "" : value.trim();
    }

    public record ParsedAddress(String houseNo, String area) {
    }
}
