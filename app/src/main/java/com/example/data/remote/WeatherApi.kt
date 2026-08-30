package com.example.data.remote

import com.squareup.moshi.Json
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import retrofit2.http.GET
import retrofit2.http.Query
import java.util.concurrent.TimeUnit

data class OpenMeteoResponse(
    @Json(name = "latitude") val latitude: Double? = null,
    @Json(name = "longitude") val longitude: Double? = null,
    @Json(name = "current") val current: CurrentWeather? = null
)

data class CurrentWeather(
    @Json(name = "time") val time: String? = null,
    @Json(name = "temperature_2m") val temperature: Double? = null,
    @Json(name = "relative_humidity_2m") val humidity: Int? = null,
    @Json(name = "apparent_temperature") val apparentTemperature: Double? = null,
    @Json(name = "precipitation") val precipitation: Double? = null,
    @Json(name = "rain") val rain: Double? = null,
    @Json(name = "weather_code") val weatherCode: Int? = null,
    @Json(name = "wind_speed_10m") val windSpeed: Double? = null
)

data class CampusWeatherSummary(
    val temperatureCelsius: Double = 27.5,
    val apparentTemperatureCelsius: Double = 29.0,
    val precipitationMm: Double = 0.0,
    val isRaining: Boolean = false,
    val weatherCondition: String = "Partly Cloudy",
    val weatherIconEmoji: String = "⛅",
    val weatherDelayMinutes: Int = 0,
    val weatherAdvisory: String = "Optimal walking conditions on campus paths."
)

interface OpenMeteoApiService {
    @GET("v1/forecast")
    suspend fun getCampusWeather(
        @Query("latitude") latitude: Double = 5.6506, // Campus Coordinates (Legon / Accra)
        @Query("longitude") longitude: Double = -0.1870,
        @Query("current") currentFields: String = "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,rain,weather_code,wind_speed_10m",
        @Query("timezone") timezone: String = "auto"
    ): OpenMeteoResponse
}

object WeatherApiClient {
    private const val BASE_URL = "https://api.open-meteo.com/"

    private val moshi = Moshi.Builder()
        .addLast(KotlinJsonAdapterFactory())
        .build()

    private val okHttpClient = OkHttpClient.Builder()
        .connectTimeout(8, TimeUnit.SECONDS)
        .readTimeout(8, TimeUnit.SECONDS)
        .build()

    val apiService: OpenMeteoApiService by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
            .create(OpenMeteoApiService::class.java)
    }

    suspend fun fetchCampusWeather(): CampusWeatherSummary {
        return try {
            val response = apiService.getCampusWeather()
            val current = response.current
            val temp = current?.temperature ?: 28.0
            val apparentTemp = current?.apparentTemperature ?: (temp + 1.5)
            val precip = current?.precipitation ?: (current?.rain ?: 0.0)
            val code = current?.weatherCode ?: 2

            val isRain = precip > 0.1 || code in listOf(51, 53, 55, 61, 63, 65, 80, 81, 82, 95, 96, 99)
            val (condition, emoji, delayMins, advisory) = interpretWeather(code, precip, temp)

            CampusWeatherSummary(
                temperatureCelsius = temp,
                apparentTemperatureCelsius = apparentTemp,
                precipitationMm = precip,
                isRaining = isRain,
                weatherCondition = condition,
                weatherIconEmoji = emoji,
                weatherDelayMinutes = delayMins,
                weatherAdvisory = advisory
            )
        } catch (e: Exception) {
            // Graceful fallback weather data
            CampusWeatherSummary(
                temperatureCelsius = 28.0,
                apparentTemperatureCelsius = 30.0,
                precipitationMm = 0.0,
                isRaining = false,
                weatherCondition = "Sunny / Clear",
                weatherIconEmoji = "☀️",
                weatherDelayMinutes = 0,
                weatherAdvisory = "Clear skies. Standard 15–20 min campus walking times apply."
            )
        }
    }

    private fun interpretWeather(code: Int, precipMm: Double, temp: Double): Quadruple<String, String, Int, String> {
        return when {
            code in listOf(95, 96, 99) -> Quadruple(
                "Thunderstorm",
                "⛈️",
                30,
                "Heavy thunderstorm detected. High-priority +30 min early wakeup buffer applied for shuttle delays and safety."
            )
            code in listOf(80, 81, 82) || precipMm >= 3.0 -> Quadruple(
                "Heavy Showers",
                "🌧️",
                25,
                "Heavy rain showers active. +25 min delay buffer added for covered walkway transitions and umbrella transit."
            )
            code in listOf(51, 53, 55, 61, 63, 65) || precipMm > 0.2 -> Quadruple(
                "Moderate Rain",
                "🌦️",
                15,
                "Wet surfaces & light rain. +15 min transit buffer added to ensure on-time lecture hall arrival."
            )
            temp >= 33.0 -> Quadruple(
                "Extreme Heat",
                "☀️",
                10,
                "High campus temperatures. +10 min buffer recommended for shaded routes and hydration stops."
            )
            code in listOf(1, 2, 3) -> Quadruple(
                "Partly Cloudy",
                "⛅",
                0,
                "Fair weather on campus. Standard walking and commute times active."
            )
            else -> Quadruple(
                "Clear Skies",
                "☀️",
                0,
                "Optimal morning weather. No transit delays expected."
            )
        }
    }
}

data class Quadruple<A, B, C, D>(val first: A, val second: B, val third: C, val fourth: D)
