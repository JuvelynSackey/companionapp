package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.entity.StudyResourceEntity
import com.example.ui.MainViewModel
import com.example.ui.components.CampusLibraryDirectoryComponent
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ResourcesScreen(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    var selectedMainTab by remember { mutableStateOf(0) } // 0 = Campus Libraries, 1 = Past Questions Vault, 2 = School Portals
    val currentInstitution by viewModel.currentInstitution.collectAsState()

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(HighDensityBg)
    ) {
        // Top Section TabRow
        PrimaryTabRow(
            selectedTabIndex = selectedMainTab,
            containerColor = HighDensityNavBg,
            contentColor = HighDensityDeepPurple,
            modifier = Modifier.fillMaxWidth()
        ) {
            Tab(
                selected = selectedMainTab == 0,
                onClick = { selectedMainTab = 0 },
                text = { Text("Libraries & Seats", fontWeight = if (selectedMainTab == 0) FontWeight.Bold else FontWeight.Medium) },
                icon = { Icon(Icons.Filled.LocalLibrary, contentDescription = null, modifier = Modifier.size(18.dp)) },
                selectedContentColor = HighDensityDeepPurple,
                unselectedContentColor = HighDensityMutedText
            )
            Tab(
                selected = selectedMainTab == 1,
                onClick = { selectedMainTab = 1 },
                text = { Text("Past Papers Vault", fontWeight = if (selectedMainTab == 1) FontWeight.Bold else FontWeight.Medium) },
                icon = { Icon(Icons.Filled.FolderZip, contentDescription = null, modifier = Modifier.size(18.dp)) },
                selectedContentColor = HighDensityDeepPurple,
                unselectedContentColor = HighDensityMutedText
            )
            Tab(
                selected = selectedMainTab == 2,
                onClick = { selectedMainTab = 2 },
                text = { Text("${currentInstitution.shortCode} Portals", fontWeight = if (selectedMainTab == 2) FontWeight.Bold else FontWeight.Medium) },
                icon = { Icon(Icons.Filled.Dns, contentDescription = null, modifier = Modifier.size(18.dp)) },
                selectedContentColor = HighDensityDeepPurple,
                unselectedContentColor = HighDensityMutedText
            )
        }

        when (selectedMainTab) {
            0 -> CampusLibraryDirectoryComponent(viewModel = viewModel)
            1 -> StudyVaultContent(viewModel = viewModel)
            2 -> com.example.ui.components.InstitutionPortalGatewayComponent(viewModel = viewModel)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun StudyVaultContent(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val resources by viewModel.allResources.collectAsState()

    var searchQuery by remember { mutableStateOf("") }
    var selectedFilter by remember { mutableStateOf("All") }
    var viewingResourceSummary by remember { mutableStateOf<StudyResourceEntity?>(null) }

    val filters = listOf("All", "Past Questions", "Formula Sheets", "Lab Practical", "Bookmarked")

    val filteredList = resources.filter { item ->
        val matchesSearch = item.courseCode.contains(searchQuery, ignoreCase = true) ||
                item.title.contains(searchQuery, ignoreCase = true) ||
                item.courseTitle.contains(searchQuery, ignoreCase = true)

        val matchesCategory = when (selectedFilter) {
            "Bookmarked" -> item.isBookmarked
            "Past Questions" -> item.title.contains("Past Questions", ignoreCase = true)
            "Formula Sheets" -> item.title.contains("Formula", ignoreCase = true) || item.title.contains("Cheatsheet", ignoreCase = true)
            "Lab Practical" -> item.title.contains("Lab", ignoreCase = true)
            else -> true
        }

        matchesSearch && matchesCategory
    }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 8.dp, bottom = 96.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // Header
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Past Questions & Study Vault",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "Curated exam revision packs, solutions & lecture summaries",
                        style = MaterialTheme.typography.bodySmall,
                        color = Slate600
                    )
                }
            }
        }

        // Search Bar
        item {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text("Search course code, exam year, or topic...") },
                leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null, tint = Slate600) },
                trailingIcon = {
                    if (searchQuery.isNotBlank()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(Icons.Filled.Close, contentDescription = "Clear")
                        }
                    }
                },
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("resource_search_field")
            )
        }

        // Filter Chips
        item {
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(vertical = 2.dp)
            ) {
                items(filters) { f ->
                    val isSelected = f == selectedFilter
                    FilterChip(
                        selected = isSelected,
                        onClick = { selectedFilter = f },
                        label = { Text(f) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = AcademicBlue,
                            selectedLabelColor = Color.White
                        )
                    )
                }
            }
        }

        // Resources List
        items(filteredList) { res ->
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("resource_card_${res.courseCode}"),
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = AcademicBlue.copy(alpha = 0.12f)
                        ) {
                            Text(
                                text = "${res.courseCode} • ${res.year}",
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.Bold,
                                color = AcademicBlue
                            )
                        }

                        IconButton(onClick = { viewModel.toggleBookmark(res) }) {
                            Icon(
                                imageVector = if (res.isBookmarked) Icons.Filled.Bookmark else Icons.Outlined.BookmarkBorder,
                                contentDescription = "Bookmark",
                                tint = if (res.isBookmarked) AcademicGold else Slate600
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(6.dp))

                    Text(
                        text = res.title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = res.courseTitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = Slate600
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = res.summaryText,
                        style = MaterialTheme.typography.bodySmall,
                        color = Slate700,
                        maxLines = 2
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.FileDownload, contentDescription = null, tint = Slate600, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "${res.downloadCount} downloads • ${res.fileSize} (${res.fileType})",
                                style = MaterialTheme.typography.labelSmall,
                                color = Slate600
                            )
                        }

                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            OutlinedButton(
                                onClick = { viewingResourceSummary = res },
                                shape = RoundedCornerShape(10.dp)
                            ) {
                                Text("Preview", style = MaterialTheme.typography.labelSmall)
                            }
                            Button(
                                onClick = { viewModel.downloadResource(res) },
                                shape = RoundedCornerShape(10.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = AcademicBlue)
                            ) {
                                Icon(Icons.Filled.Download, contentDescription = null, modifier = Modifier.size(14.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Open", style = MaterialTheme.typography.labelSmall)
                            }
                        }
                    }
                }
            }
        }
    }

    // Resource Summary Modal
    viewingResourceSummary?.let { item ->
        AlertDialog(
            onDismissRequest = { viewingResourceSummary = null },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Description, contentDescription = null, tint = AcademicBlue)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("${item.courseCode} Resource Pack")
                }
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(text = item.title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text(text = "Subject: ${item.courseTitle} (${item.year})", style = MaterialTheme.typography.bodySmall, color = Slate600)
                    Divider()
                    Text(
                        text = "📝 Key Study Topics Covered:\n\n${item.summaryText}",
                        style = MaterialTheme.typography.bodyMedium,
                        lineHeight = 22.sp
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.downloadResource(item)
                        viewingResourceSummary = null
                    }
                ) {
                    Text("Download Document")
                }
            },
            dismissButton = {
                TextButton(onClick = { viewingResourceSummary = null }) {
                    Text("Close")
                }
            }
        )
    }
}

