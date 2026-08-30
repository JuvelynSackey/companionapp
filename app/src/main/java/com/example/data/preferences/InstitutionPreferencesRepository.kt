package com.example.data.preferences

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import java.io.IOException

val Context.institutionDataStore: DataStore<Preferences> by preferencesDataStore(name = "campusflow_user_preferences")

class InstitutionPreferencesRepository(private val context: Context) {

    private object PreferenceKeys {
        val KEY_SELECTED_INSTITUTION_ID = stringPreferencesKey("selected_institution_id")
        val KEY_IS_ONBOARDING_COMPLETED = booleanPreferencesKey("is_onboarding_completed")
        val KEY_IMPORT_SAMPLE_DATA = booleanPreferencesKey("import_sample_data")
        val KEY_SELECTED_ROLE = stringPreferencesKey("selected_user_role")
    }

    val selectedInstitutionId: Flow<String?> = context.institutionDataStore.data
        .catch { exception ->
            if (exception is IOException) {
                emit(emptyPreferences())
            } else {
                throw exception
            }
        }
        .map { preferences ->
            preferences[PreferenceKeys.KEY_SELECTED_INSTITUTION_ID]
        }

    val isOnboardingCompleted: Flow<Boolean> = context.institutionDataStore.data
        .catch { exception ->
            if (exception is IOException) {
                emit(emptyPreferences())
            } else {
                throw exception
            }
        }
        .map { preferences ->
            preferences[PreferenceKeys.KEY_IS_ONBOARDING_COMPLETED] ?: false
        }

    val isImportSampleDataEnabled: Flow<Boolean> = context.institutionDataStore.data
        .catch { exception ->
            if (exception is IOException) {
                emit(emptyPreferences())
            } else {
                throw exception
            }
        }
        .map { preferences ->
            preferences[PreferenceKeys.KEY_IMPORT_SAMPLE_DATA] ?: true
        }

    val savedUserRole: Flow<String> = context.institutionDataStore.data
        .catch { exception ->
            if (exception is IOException) {
                emit(emptyPreferences())
            } else {
                throw exception
            }
        }
        .map { preferences ->
            preferences[PreferenceKeys.KEY_SELECTED_ROLE] ?: "STUDENT"
        }

    suspend fun saveSelectedInstitution(institutionId: String, completedOnboarding: Boolean = true, importSampleData: Boolean = true) {
        context.institutionDataStore.edit { preferences ->
            preferences[PreferenceKeys.KEY_SELECTED_INSTITUTION_ID] = institutionId
            preferences[PreferenceKeys.KEY_IS_ONBOARDING_COMPLETED] = completedOnboarding
            preferences[PreferenceKeys.KEY_IMPORT_SAMPLE_DATA] = importSampleData
        }
    }

    suspend fun saveUserRole(roleName: String) {
        context.institutionDataStore.edit { preferences ->
            preferences[PreferenceKeys.KEY_SELECTED_ROLE] = roleName
        }
    }

    suspend fun resetOnboarding() {
        context.institutionDataStore.edit { preferences ->
            preferences[PreferenceKeys.KEY_IS_ONBOARDING_COMPLETED] = false
        }
    }

    suspend fun clearAllPreferences() {
        context.institutionDataStore.edit { preferences ->
            preferences.clear()
        }
    }
}
