using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using bootselector.Models;
using bootselector.Services;

namespace bootselector;

public partial class MainWindow : Window
{
    private readonly IBootService _bootService;
    private List<BootEntry> _bootEntries = new();

    public MainWindow()
    {
        InitializeComponent();
        
        _bootService = BootServiceFactory.GetBootService();
        PlatformLabel.Text = $"Platform: {_bootService.PlatformName}";
        
        // Load boot entries on startup
        Loaded += async (_, _) => await LoadBootEntriesAsync();
    }

    private async Task LoadBootEntriesAsync()
    {
        try
        {
            BootEntryComboBox.IsEnabled = false;
            RefreshButton.IsEnabled = false;
            
            _bootEntries = await _bootService.GetBootEntriesAsync();
            
            BootEntryComboBox.ItemsSource = _bootEntries;
            BootEntryComboBox.DisplayMemberBinding = new Avalonia.Data.Binding("DisplayName");
            
            if (_bootEntries.Count > 0)
            {
                // Select the current boot entry, or first one
                var current = _bootEntries.FirstOrDefault(e => e.IsCurrent) ?? _bootEntries[0];
                BootEntryComboBox.SelectedItem = current;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading boot entries: {ex.Message}");
        }
        finally
        {
            BootEntryComboBox.IsEnabled = true;
            RefreshButton.IsEnabled = true;
        }
    }

    private async void RefreshButton_Click(object? sender, RoutedEventArgs e)
    {
        await LoadBootEntriesAsync();
    }

    private async void SetNextBootButton_Click(object? sender, RoutedEventArgs e)
    {
        await SetNextBootAsync(restart: false);
    }

    private async void RestartButton_Click(object? sender, RoutedEventArgs e)
    {
        await SetNextBootAsync(restart: true);
    }

    private async Task SetNextBootAsync(bool restart)
    {
        if (BootEntryComboBox.SelectedItem is not BootEntry selectedEntry)
        {
            return;
        }

        try
        {
            SetNextBootButton.IsEnabled = false;
            RestartButton.IsEnabled = false;

            await _bootService.SetNextBootAsync(selectedEntry, restart);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
        }
        finally
        {
            SetNextBootButton.IsEnabled = true;
            RestartButton.IsEnabled = true;
        }
    }

    // Custom title bar drag
    private void TitleBar_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        if (e.GetCurrentPoint(this).Properties.IsLeftButtonPressed)
        {
            BeginMoveDrag(e);
        }
    }

    private void MinimizeButton_Click(object? sender, RoutedEventArgs e)
    {
        WindowState = WindowState.Minimized;
    }

    private void CloseButton_Click(object? sender, RoutedEventArgs e)
    {
        Close();
    }
}